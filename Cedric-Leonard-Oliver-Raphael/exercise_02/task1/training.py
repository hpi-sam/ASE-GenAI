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
USE_TEST_SET_PERMUTATIONS = True


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
    weakly_correlated_cols = []#"Question.ID"]#, "Answer.confidence", "Worker.country", "Worker.profession", "Worker.programmingLanguage", "Worker.whereLearnedToCode", "Worker.yearsOfExperience", "Worker.age", "Worker.gender", "Worker.score", "Answer.difficulty", "Answer.duration"]
    drop_cols = ["TP", "TN", "FN", "FP", "Answer.ID", "Worker.ID", "Answer.explanation", "Answer.option"]
    df = df.drop(columns=drop_cols+weakly_correlated_cols)

    # Encode categorical variables
    categorical_columns = ["FailingMethod", "Answer.option", "Worker.profession", "Worker.gender",
                           "Worker.whereLearnedToCode", "Worker.country", "Worker.programmingLanguage"]
    categorical_columns = [col for col in categorical_columns if col in df.columns]
    for col in categorical_columns:
        le = LabelEncoder()
        df[col] = le.fit_transform(df[col])

    return df


def split_data(df, test_indices, target_col="GroundTruth"):
    # Separate target and features
    X = df.drop(columns=[target_col])
    y = df[target_col]

    # Split based on `FailingMethod`
    unique_methods = X['FailingMethod'].unique()
    test_methods = unique_methods[test_indices]  # take the last two methods as test

    train_data = X[~X['FailingMethod'].isin(test_methods)]
    test_data = X[X['FailingMethod'].isin(test_methods)]

    train_labels = y[~X['FailingMethod'].isin(test_methods)]
    test_labels = y[X['FailingMethod'].isin(test_methods)]

    return train_data, test_data, train_labels, test_labels


def normalize_data(train_data, test_data, continuous_columns):
    scaler = MinMaxScaler()
    train_data[continuous_columns] = scaler.fit_transform(train_data[continuous_columns])
    test_data[continuous_columns] = scaler.transform(test_data[continuous_columns])
    return train_data, test_data


def analyze_feature_importance(clf, feature_names, test_failing_methods):
    importances = clf.feature_importances_
    std = np.std([tree.feature_importances_ for tree in clf.estimators_], axis=0)
    forest_importances = pd.Series(importances, index=feature_names)
    
    # Sort the importances by value
    forest_importances = forest_importances.sort_values(ascending=False)
    
    # Rearrange std according to sorted order
    std = std[np.argsort(importances)[::-1]]  # Use sorted indices to rearrange std

    # Plot the sorted importances
    fig, ax = plt.subplots()
    forest_importances.plot.bar(yerr=std, ax=ax)
    ax.set_title("Feature importances using MDI")
    ax.set_ylabel("Mean decrease in impurity")
    fig.tight_layout()
    fig.savefig(f'exercise_02/task1/results/{CURRENT_EXPERIMENT}/explainability_{test_failing_methods[0]}_{test_failing_methods[1]}.png')
    plt.close(fig)
    

def train_and_evaluate_model(train_data, train_labels, test_data, test_labels, feature_names, train_metrics, test_metrics):
    # Extract FailingMethod before dropping it
    failing_methods_train = train_data['FailingMethod']
    failing_methods_test = test_data['FailingMethod']

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

    logging.info(f"Best hyperparameters: {grid_search.best_params_}")

    # Cross-validation evaluation with the best model
    y_pred_cv = cross_val_predict(best_clf, train_data, train_labels, cv=cv)
    val_precision = precision_score(train_labels, y_pred_cv)
    val_recall = recall_score(train_labels, y_pred_cv)

    # Predict on train data
    y_pred_train = best_clf.predict(train_data)

    logging.info("\n####################################")
    logging.info(f"EVALUATION with Test-Set: {failing_methods_test.unique()}")
    logging.info(f"Cross-validated Precision: {val_precision}, Recall: {val_recall}")

    # Evaluate on the test set
    y_pred_test = best_clf.predict(test_data)
    test_precision = precision_score(test_labels, y_pred_test)
    test_recall = recall_score(test_labels, y_pred_test)
    logging.info(f"Test Precision: {test_precision}, Recall: {test_recall}")

    # Feature Importance
    analyze_feature_importance(best_clf, feature_names, failing_methods_test.unique())
    # Distribution
    distribution_of_correct_labels("RTTR", test_data, y_pred_test, test_labels, failing_methods_test.unique(), experiment_dir=experiment_dir)
    distribution_of_correct_labels("ExplanationLength", test_data, test_labels, y_pred_test, failing_methods_test.unique(), experiment_dir=experiment_dir)

    # Grouped evaluation by FailingMethod
    # Cross-validation grouped metrics
    logging.info("\nTrain Grouped Metrics:")
    for method in failing_methods_train.unique():
        mask = (failing_methods_train == method)
        if mask.sum() > 0:  # Avoid zero samples
            method_precision = precision_score(train_labels[mask], y_pred_train[mask])
            method_recall = recall_score(train_labels[mask], y_pred_train[mask])
            train_metrics[method]['precision'].append(method_precision)
            train_metrics[method]['recall'].append(method_recall)
            logging.info(f"FailingMethod: {method}, Precision: {method_precision:.2f}, Recall: {method_recall:.2f}")

    # Test set grouped metrics
    logging.info("\nTest Set Grouped Metrics:")
    for method in failing_methods_test.unique():
        mask = (failing_methods_test == method)
        if mask.sum() > 0:  # Avoid zero samples
            method_precision = precision_score(test_labels[mask], y_pred_test[mask])
            method_recall = recall_score(test_labels[mask], y_pred_test[mask])
            test_metrics[method]['precision'].append(method_precision)
            test_metrics[method]['recall'].append(method_recall)
            logging.info(f"FailingMethod: {method}, Precision: {method_precision:.2f}, Recall: {method_recall:.2f}")

    return test_precision, test_recall
    
    
def generate_tuple_permutations(n):
    permutations = []
    for i in range(0, n):
        for j in range(0, n):
            if [j, i] not in permutations and i != j:
                permutations.append([i,j])
    return permutations


def distribution_of_correct_labels(by, test_data, test_labels, y_pred_test, failing_methods, experiment_dir):
    # Add a column to the test_data DataFrame for predicted labels
    test_data['Predicted_Label'] = y_pred_test

    # Filter the DataFrame to include only correct predictions
    correct_mask = (test_labels == y_pred_test)
    correct_data = test_data[correct_mask]

    # Create a boxplot for the distribution of the "by" variable, grouped by predicted labels
    fig, ax = plt.subplots(figsize=(10, 6))
    sns.boxplot(x='Predicted_Label', y=by, data=correct_data, ax=ax)

    # Set plot title and labels
    ax.set_title(f'Distribution of Correct Labels by {by}')
    ax.set_xlabel('Predicted Label')
    ax.set_ylabel(by)

    # Save the plot
    fig.tight_layout()
    plot_path = f'{experiment_dir}/correct_labels_boxplot_by_{by}_{failing_methods[0]}_{failing_methods[1]}.png'
    fig.savefig(plot_path)
    plt.close(fig)

CURRENT_EXPERIMENT = "test"

if __name__ == "__main__":
    experiment_dir = f'exercise_02/task1/results/{CURRENT_EXPERIMENT}'
    os.makedirs(experiment_dir, exist_ok=True)
    
    logging.basicConfig(
        filename=f'{experiment_dir}/experiment.log',
        filemode='w',
        format='%(message)s',
        level=logging.INFO,
    )
    data_dir = 'exercise_02/data/'
    df = pd.read_csv(os.path.join(data_dir, 'answerList_data.csv'))
    halstead_volumes = pd.read_csv(os.path.join(data_dir, 'halstead_volumes.csv'), sep=';')
    df = preprocess_data(df, halstead_volumes)
    logging.info(f"Columns: {df.columns}")
    
    test_permutations = [[6, 7]] 
    if USE_TEST_SET_PERMUTATIONS:
        test_permutations = generate_tuple_permutations(n=8)
    precision, recall = 0.0, 0.0

    # Initialize metrics dictionaries
    train_metrics = {method: {'precision': [], 'recall': []} for method in df['FailingMethod'].unique()}
    test_metrics = {method: {'precision': [], 'recall': []} for method in df['FailingMethod'].unique()}

    for permutations in test_permutations:
        train_data, test_data, train_labels, test_labels = split_data(df, permutations)
        feature_names = train_data.columns

        if NORMALIZE_CONTINOUS_FEATURES:
            continuous_columns = ["Answer.duration", "Answer.confidence", "Answer.difficulty",
                                  "Worker.score", "Worker.yearsOfExperience", "Worker.age"]
            train_data, test_data = normalize_data(train_data, test_data, continuous_columns)
            
        test_precision, test_recall = train_and_evaluate_model(
            train_data, train_labels, test_data, test_labels, feature_names, 
            train_metrics, test_metrics
        )
        precision += test_precision
        recall += test_recall

    precision = precision / len(test_permutations)
    recall = recall / len(test_permutations)
    
    # Calculate averages for FailingMethod metrics
    avg_train_metrics = {int(method): {
        'precision': sum(values['precision']) / len(values['precision']) if values['precision'] else 0,
        'recall': sum(values['recall']) / len(values['recall']) if values['recall'] else 0,
    } for method, values in train_metrics.items()}

    avg_test_metrics = {int(method): {
        'precision': sum(values['precision']) / len(values['precision']) if values['precision'] else 0,
        'recall': sum(values['recall']) / len(values['recall']) if values['recall'] else 0,
    } for method, values in test_metrics.items()}

    logging.info("\n####################################")
    logging.info(f"AVERAGE TEST PRECISION: {precision}")
    logging.info(f"AVERAGE TEST RECALL: {recall}")
    
    logging.info("\nTRAIN METRICS PER FAILING METHOD:")
    logging.info(train_metrics)
    logging.info("\nTEST METRICS PER FAILING METHOD:")
    logging.info(test_metrics)
    
    logging.info("\nAVERAGE TRAIN METRICS PER FAILING METHOD:")
    logging.info(avg_train_metrics)
    logging.info("\nAVERAGE TEST METRICS PER FAILING METHOD:")
    logging.info(avg_test_metrics)
    
    if USE_TEST_SET_PERMUTATIONS:
        failing_methods = list(avg_train_metrics.keys())
        precision_train = [avg_train_metrics[method]['precision'] for method in failing_methods]
        recall_train = [avg_train_metrics[method]['recall'] for method in failing_methods]
        precision_test = [avg_test_metrics[method]['precision'] for method in failing_methods]
        recall_test = [avg_test_metrics[method]['recall'] for method in failing_methods]

        x = np.arange(len(failing_methods))
        bar_width = 0.2
        gap = 0.2  # Gap between precision and recall groups

        fig, ax = plt.subplots(figsize=(10, 6))
        ax.bar(x - bar_width - gap / 2, precision_train, bar_width, label='Precision (Train)', color='blue', alpha=0.7)
        ax.bar(x - gap / 2, precision_test, bar_width, label='Precision (Test)', color='skyblue', alpha=0.7)
        ax.bar(x + gap / 2, recall_train, bar_width, label='Recall (Train)', color='green', alpha=0.7)
        ax.bar(x + bar_width + gap / 2, recall_test, bar_width, label='Recall (Test)', color='lightgreen', alpha=0.7)

        ax.set_xlabel('Failing Methods', fontsize=12)
        ax.set_ylabel('Metric Score', fontsize=12)
        ax.set_title('Evaluation Metrics by Failing Method', fontsize=14)
        ax.set_xticks(x)
        ax.set_xticklabels(failing_methods, fontsize=10)
        ax.legend(fontsize=10)

        ax.grid(axis='y', linestyle='--', alpha=0.7)
        plt.tight_layout()
        plt.savefig(f'{experiment_dir}/evaluation_metrics_grouped.png')
        plt.close()
        

