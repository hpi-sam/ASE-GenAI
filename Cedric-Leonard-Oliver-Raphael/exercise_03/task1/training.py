import pandas as pd
import numpy as np
from sklearn.model_selection import StratifiedKFold, GridSearchCV, cross_val_predict
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import precision_score, recall_score
from sklearn.preprocessing import LabelEncoder, MinMaxScaler
from transformers import AutoTokenizer, AutoModel
import torch
import os
import matplotlib.pyplot as plt
import logging
import seaborn as sns

USE_RTTR = True
USE_HALSTEAD = True
USE_CODE_EMBEDDINGS = False
USE_TEXT_EMBEDDINGS = False
NORMALIZE_CONTINOUS_FEATURES = False
USE_ENGINEERED_GROUND_TRUTH = True

class TransformerDataset(torch.utils.data.Dataset):
    def __init__(self, texts, tokenizer, max_len=128):
        self.texts = texts
        self.tokenizer = tokenizer
        self.max_len = max_len

    def __len__(self):
        return len(self.texts)

    def __getitem__(self, idx):
        encoded = self.tokenizer(
            self.texts[idx],
            padding='max_length',
            truncation=True,
            max_length=self.max_len,
            return_tensors="pt"
        )
        return encoded['input_ids'].squeeze(0), encoded['attention_mask'].squeeze(0)


def embed_text_or_code(texts, model_name="bert-base-uncased", max_len=128):
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModel.from_pretrained(model_name)
    dataset = TransformerDataset(texts, tokenizer, max_len=max_len)
    dataloader = torch.utils.data.DataLoader(dataset, batch_size=16)

    embeddings = []
    model.eval()
    with torch.no_grad():
        for input_ids, attention_mask in dataloader:
            outputs = model(input_ids=input_ids, attention_mask=attention_mask)
            embeddings.append(outputs.last_hidden_state.mean(dim=1).numpy())
    return np.vstack(embeddings)

def calculate_rttr_for_text(text, tokenizer, max_len=128):
    tokens = tokenizer.tokenize(text, max_length=max_len, truncation=True)
    unique_tokens = set(tokens)
    total_tokens = len(tokens)
    if total_tokens == 0:  # Handle edge case for empty text
        return 0.0
    return len(unique_tokens) / np.sqrt(total_tokens)

def preprocess_data(df, halstead_volumes, max_len_code=512, max_len_text=512):
    """Preprocess the dataset, including embedding, feature engineering, and encoding."""

    if USE_CODE_EMBEDDINGS:
        # Embed unique Java files
        unique_methods = df["FailingMethod"].unique()
        method_to_code = {}
        for method in unique_methods:
            file_path = os.path.join(data_dir, f"{method}.java")
            with open(file_path, "r") as file:
                method_to_code[method] = file.read()

        # Generate embeddings for all unique snippets
        code_snippets = list(method_to_code.values())
        code_embeddings = embed_text_or_code(
            code_snippets, model_name="microsoft/codebert-base", max_len=max_len_code
        )
        method_to_embedding = dict(zip(method_to_code.keys(), code_embeddings))
        df["CodeEmbedding"] = df["FailingMethod"].map(method_to_embedding)

        # Flatten code embeddings
        code_embeddings = np.vstack(df["CodeEmbedding"])
        embedding_columns_code = [f"CodeEmbedding_{i}" for i in range(code_embeddings.shape[1])]
        code_embedding_df = pd.DataFrame(code_embeddings, columns=embedding_columns_code, index=df.index)

        df = pd.concat([df.drop(columns=["CodeEmbedding"]), code_embedding_df])

    # Fill missing values in the 'Answer.explanation' column
    df["Answer.explanation"] = df["Answer.explanation"].fillna("")

    if USE_TEXT_EMBEDDINGS:
        # Embed textual features
        text_embeddings = embed_text_or_code(df["Answer.explanation"].tolist(), max_len=max_len_text)

        # Flatten text embeddings
        embedding_columns_explanation = [f"Answer.explanation_{i}" for i in range(text_embeddings.shape[1])]
        text_embedding_df = pd.DataFrame(text_embeddings, columns=embedding_columns_explanation, index=df.index)

        df = pd.concat([df, text_embedding_df])

    # Calculate RTTR
    if USE_RTTR:
        tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")
        df["RTTR"] = df["Answer.explanation"].apply(lambda text: calculate_rttr_for_text(text, tokenizer, max_len_text))

    if USE_HALSTEAD:
        # Create a mapping from `FailingMethod` to `HalsteadVolume`
        halstead_metrics = ['HalsteadVolume', 'HalsteadLength', 'HalsteadDifficulty', 'HalsteadEffort', 'HalsteadVocabulary']
        for metric in halstead_metrics:
            halstead_mapping = dict(zip(halstead_volumes["FailingMethod"], halstead_volumes[metric]))
            df[metric] = df["FailingMethod"].map(halstead_mapping)

    # Engineer ground truth
    if USE_ENGINEERED_GROUND_TRUTH:
        # Convert Answer.option to integer: 1 if "YES", else 0
        df["Answer.option"] = df["Answer.option"].apply(lambda x: 1 if x == "YES" else 0)

        # Override GroundTruth: 1 if GroundTruth == Answer.option, else 0
        df["GroundTruth"] = df.apply(lambda row: 1 if row["GroundTruth"] == row["Answer.option"] else 0, axis=1)

    # Engineer Explanation Length
    df["ExplanationLength"] = df["Answer.explanation"].apply(lambda x: len(x))

    # Drop uninformative columns
    weakly_correlated_cols = []#"Question.ID"]#, "Answer.confidence", "Worker.country", "Worker.programmingLanguage", "Worker.whereLearnedToCode", "Worker.yearsOfExperience", "Worker.age", "Worker.gender", "Worker.score", "Answer.difficulty", "Answer.duration"]
    drop_cols = ["TP", "TN", "FN", "FP", "Answer.ID", "Worker.ID", "Answer.explanation", "Answer.option"]
    df = df.drop(columns=drop_cols+weakly_correlated_cols)

    # Encode categorical variables
    categorical_columns = ["FailingMethod", "Answer.option", "Worker.gender",
                           "Worker.whereLearnedToCode", "Worker.country", "Worker.programmingLanguage"]
    categorical_columns = [col for col in categorical_columns if col in df.columns]
    for col in categorical_columns:
        le = LabelEncoder()
        df[col] = le.fit_transform(df[col])

    # DIFFERENCE TO MINI PROJECT 2
    # Encode profession in column that is not named exactly like the input column (for later distinction)
    le_profession = LabelEncoder()
    df["Worker.profession_encoded"] = le_profession.fit_transform(df["Worker.profession"])

    return df

def split_student_data_in_train_and_test(students_df, test_indices, target_col):
    """Split student data in train and test based on the permutation for the failing methods in test"""

    # Separate target and features
    X = students_df.drop(columns=[target_col])
    y = students_df[target_col]

    # Split based on `FailingMethod`
    unique_methods = X['FailingMethod'].unique()
    test_methods = unique_methods[test_indices]  # take the last two methods as test

    train_data = X[~X['FailingMethod'].isin(test_methods)]
    test_data = X[X['FailingMethod'].isin(test_methods)]

    train_labels = y[~X['FailingMethod'].isin(test_methods)]
    test_labels = y[X['FailingMethod'].isin(test_methods)]

    return train_data, test_data, train_labels, test_labels

def split_by_student_status(df):
    """Split the data into students and non students"""

    # Case-insensitive search for "graduate" should match both Undergraduate as well as Graduate
    students_df = df[df['Worker.profession'].str.contains('graduate', case=False, na=False)]
    non_students_df = df[~df['Worker.profession'].str.contains('graduate', case=False, na=False)]

    # Drop profession column as its not needed anymore (we only use the profession_encoded variant)
    students_df = students_df.drop("Worker.profession", axis=1)
    non_students_df = non_students_df.drop("Worker.profession", axis=1)

    return students_df, non_students_df

CONTINUOUS_COLUMNS = ["Answer.duration", "Answer.confidence", "Answer.difficulty",
                      "Worker.score", "Worker.yearsOfExperience", "Worker.age"]

def normalize_train_data(train_data):
    """Normalize continuous columns in train_data by fitting a MinMaxScaler"""
    scaler = MinMaxScaler()
    train_data[CONTINUOUS_COLUMNS] = scaler.fit_transform(train_data[CONTINUOUS_COLUMNS])
    return train_data, scaler

def normalize_test_data(scaler_for_train, test_data):
    """Normalize continuous columns in test data with the MinMaxScaler that was fit on the train data"""
    test_data[CONTINUOUS_COLUMNS] = scaler_for_train.transform(test_data[CONTINUOUS_COLUMNS])
    return test_data

def train_model(train_data, train_labels):
    """Train the student model based on the given data and labels"""

    # Define the model
    clf = RandomForestClassifier(random_state=42)

    # Define hyperparameter grid
    param_grid = {
        'n_estimators': [25, 50, 100],
        'max_depth': [10, 20, 30],
        'min_samples_split': [2, 5, 10],
        'min_samples_leaf': [1, 2, 4],
    }

    # Set up cross-validation and GridSearchCV
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    grid_search = GridSearchCV(clf, param_grid, scoring='precision', cv=cv, n_jobs=8, verbose=1)

    # Fit GridSearchCV
    grid_search.fit(train_data, train_labels)
    best_clf = grid_search.best_estimator_

    logging.info(f"Best hyperparameters for student model: {grid_search.best_params_}")

    # Cross-validation evaluation with the best model
    y_pred_cv = cross_val_predict(best_clf, train_data, train_labels, cv=cv)
    val_precision = precision_score(train_labels, y_pred_cv)
    val_recall = recall_score(train_labels, y_pred_cv)

    logging.info("\n####################################")
    logging.info(f"Cross-validation for student model - Precision: {val_precision}, Recall: {val_recall}")

    return best_clf

def evaluate_model(model, test_data, test_labels):
    """Evaluates the model on the test set"""
    y_pred_test = model.predict(test_data)
    test_precision = precision_score(test_labels, y_pred_test)
    test_recall = recall_score(test_labels, y_pred_test)

    return test_precision, test_recall

CURRENT_EXPERIMENT = "one_test_set_permutation"

if __name__ == "__main__":
    # AT LEAST FOR ME (Olli) THIS WAS NECESSARY TO PLOT
    # https://stackoverflow.com/questions/14694408/runtimeerror-main-thread-is-not-in-main-loop#14695007
    plt.switch_backend('agg')

    experiment_dir = f'exercise_03/task1/results/{CURRENT_EXPERIMENT}'
    os.makedirs(experiment_dir, exist_ok=True)

    logging.basicConfig(
        filename=f'{experiment_dir}/experiment.log',
        filemode='w',
        format='%(message)s',
        level=logging.INFO,
    )
    data_dir = 'exercise_03/data/'
    df = pd.read_csv(os.path.join(data_dir, 'answerList_data.csv'))
    halstead_volumes = pd.read_csv(os.path.join(data_dir, 'halstead_volumes.csv'), sep=';')
    df = preprocess_data(df, halstead_volumes)
    logging.info(f"Columns: {df.columns}")

    # Split data into students and non-students in order to only train on student data.
    students_df, non_students_df = split_by_student_status(df)
    logging.info(f"\nTraining based on {len(students_df)} student answers from a total of {len(df)} answers\n")

    # Hardcode that for training on students we only use failing methods 0-5,
    # so the test set then consists of all student answers for failing methods 6 and 7
    # plus the gradually growing number of non student answers (independet of the failing method!)
    permutation = [6, 7]
    logging.info("Training based failing methods 0-5 for students, 6 & 7 used for test")

    target_col = "GroundTruth"
    # Split student data in train and test
    train_data, test_data, train_labels, test_labels = split_student_data_in_train_and_test(students_df, permutation, target_col)

    # Normalize train data if needed.
    if NORMALIZE_CONTINOUS_FEATURES:
        train_data, scaler_for_train = normalize_train_data(train_data)

    # Train model on student data
    model = train_model(train_data, train_labels)

    number_of_non_students = len(non_students_df)
    non_students_to_add_to_test = None

    # Initialize test metrics
    test_metrics = {number: {'precision': 0.0, 'recall': 0.0} for number in range(number_of_non_students + 1)}

    for current_number_of_non_students in range(number_of_non_students + 1):
        # (0,1,...,number_of_non_students)

        # At first, no non-student is added.
        if current_number_of_non_students > 0:
            # Sample a random non-student answer
            random_non_student_answer = non_students_df.sample(random_state=42, n=1)
            # Drop this answer from the non_students_df to prevent repicking it next time
            non_students_df = non_students_df.drop(random_non_student_answer.index)

            if non_students_to_add_to_test is None:
                # There is only one non student to add first
                non_students_to_add_to_test = random_non_student_answer
            else:
                # Add new random selection to previously added non student answers
                # Reason: *Gradually adding* and not always doing a new random selection.
                non_students_to_add_to_test = pd.concat([non_students_to_add_to_test, random_non_student_answer])

            # Separate target_col in non_student data from features
            X_non_students = non_students_to_add_to_test.drop(columns=[target_col])
            y_non_students = non_students_to_add_to_test[target_col]

            # Concat the test_data with the new non-student data
            test_data = pd.concat([test_data, X_non_students])
            test_labels = pd.concat([test_labels, y_non_students])

        # Normalize test data if needed.
        if NORMALIZE_CONTINOUS_FEATURES:
            test_data = normalize_test_data(scaler_for_train, test_data)

        # Evaluate on test
        test_precision, test_recall = evaluate_model(model, test_data, test_labels)
        test_metrics[current_number_of_non_students]['precision'] = test_precision
        test_metrics[current_number_of_non_students]['recall'] = test_recall

        logging.info("\n####################################")
        logging.info(f"NUMBER OF NON-STUDENTS ADDED TO TEST: {current_number_of_non_students}")
        logging.info(f"TEST PRECISION: {test_precision}")
        logging.info(f"TEST RECALL: {test_recall}")

    # Plot test recall and precision by numbers of non-student answers added.
    x_values = range(number_of_non_students + 1)
    y_test_precision = [test_metrics[number]['precision'] for number in range(number_of_non_students + 1)]
    y_test_recall = [test_metrics[number]['recall'] for number in range(number_of_non_students + 1)]

    fig, ax = plt.subplots(figsize=(10, 6))
    ax.plot(x_values, y_test_precision, label='Precision')
    ax.plot(x_values, y_test_recall, label='Recall')
    ax.set_xlabel('Number of non-student answers added to test', fontsize=12)
    ax.set_ylabel('Metric score on test', fontsize=12)
    ax.set_title('Evaluation metrics by number of non-student answers added', fontsize=14)
    ax.legend(fontsize=10)
    plt.tight_layout()
    plt.savefig(f'{experiment_dir}/evaluation_metrics_by_non_student_answers_added.png')
    plt.close()