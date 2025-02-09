import os
import pandas as pd
from sklearn.metrics import classification_report
from sklearn.tree import DecisionTreeClassifier
import numpy as np
import matplotlib.pyplot as plt

from get_value_of_bug_description import Thinker

ANSWERS_FILE = "./data/answerList_data.csv"

def number_of_words(expl):
    return len(expl.split(" "))

def get_ground_truth(df: pd.DataFrame) -> pd.DataFrame:
    """
    Read all files from ./prompts. Each filename is the ID of an answer and contains the score of the answer.
    Those tuples represent the ground truth.
    """
    ground_truth = []

    # Get all files in folder ./prompts
    files = os.listdir("./prompts")
    for file in files:
        with open(f"./prompts/{file}", "r") as f:
            score = int(f.read())
            ground_truth.append( (file.replace(".txt", ""), score) )
    return pd.DataFrame(ground_truth, columns=["Answer.ID", "GroundTruth"])

def prepare_data(df, explanation_complexity_method, outfolder):
    def score_for_where_learned_to_code(where_learned_to_code):
        score = 0
        if 'University' in where_learned_to_code:
            score += 1000
        if 'High School' in where_learned_to_code:
            score += 100
        if 'Web' in where_learned_to_code:
            score += 50
        if 'Books' in where_learned_to_code:
            score += 100
        return score

    def score_for_programming_languages(pls):
        known_languages = ['java', 'python', 'javascript', 'c', 'c++', 'c#', 'ruby', 'php', 'sql', 'html', 'css', 'xml', 'json', 'bash', 'shell', 'perl', 'go', 'rust', 'kotlin', 'swift', 'objective-c', 'scala', 'haskell', 'erlang', 'elixir', 'clojure', 'groovy', 'lisp', 'prolog', 'r']

        score = 0
        for pl in known_languages:
            if pl in pls.lower():
                score += 1
        return score

    explanations_raw = df['Answer.explanation'].tolist()
    explanation_ids_raw = df['Answer.ID'].tolist()

    explanation_complexities = []
    for i in range(len(explanations_raw)):
        expl = explanations_raw[i]
        id = explanation_ids_raw[i]
        explanation_complexities.append(explanation_complexity_method(str(expl), prompt_id=f"{id}", stdout=True))

    df['Answer.explanationComplexity'] = explanation_complexities

    genders = df['Worker.gender'].unique().tolist()
    countries = df['Worker.country'].unique().tolist()
    answers = df['Answer.option'].unique().tolist()
    failing_methods = df['FailingMethod'].unique().tolist()
    prepared_data = df.copy()

    prepared_data['Worker.country'] = [countries.index(country) for country in df['Worker.country'].tolist()]
    prepared_data['Answer.option'] = [answers.index(answer) for answer in df['Answer.option'].tolist()]
    prepared_data['FailingMethod'] = [failing_methods.index(method) for method in df['FailingMethod'].tolist()]
    prepared_data['Worker.gender'] = [genders.index(gender) for gender in df['Worker.gender'].tolist()]

    prepared_data.to_csv(f"./out/{outfolder}/prepared_data1.csv")

    prepared_data['Worker.whereLearnedToCode'] = [score_for_where_learned_to_code(where_learned_to_code) for where_learned_to_code in df['Worker.whereLearnedToCode'].tolist()]
    prepared_data['Worker.programmingLanguage'] = [score_for_programming_languages(str(pl)) for pl in df['Worker.programmingLanguage'].tolist()]

    prepared_data.to_csv(f"./out/{outfolder}/prepared_data2.csv")
    return prepared_data


def train_classifier(X_training_set, y_training_set):
    dtc = DecisionTreeClassifier()
    dtc.fit(X_training_set, y_training_set)
    return dtc


def main():
    ones_precision = []
    zeros_precision = []
    ones_recall = []
    zeros_recall = []

    thinker = Thinker()
    explanation_complexity_method = thinker.score_explanation

    df = pd.read_csv(ANSWERS_FILE)
    students_df = df[df['Worker.profession'].isin(["Graduate_Student", "Undergraduate_Student"])]
    non_students_df = df[~df['Worker.profession'].isin(["Graduate_Student", "Undergraduate_Student"])]

    prepared_students_df = prepare_data(students_df, explanation_complexity_method, "students")
    prepared_graduates_df = prepared_students_df[prepared_students_df['Worker.profession'].isin(["Graduate_Student"])]
    prepared_undergraduates_df = prepared_students_df[prepared_students_df['Worker.profession'].isin(["Undergraduate_Student"])]
    prepared_non_students_df = prepare_data(non_students_df, explanation_complexity_method, "non_students")

    shuffled_prepared_non_students_df = prepared_non_students_df.sample(frac=1).reset_index(drop=True)
    X_shuffled_prepared_non_students_df = shuffled_prepared_non_students_df.drop(columns=['GroundTruth', 'TP', 'FP', 'TN', 'FN', 'Answer.explanation', 'Worker.profession', 'Worker.ID'])
    y_shuffled_prepared_non_students_df = shuffled_prepared_non_students_df['GroundTruth']

    X_graduates_set = prepared_graduates_df.drop(columns=['GroundTruth', 'TP', 'FP', 'TN', 'FN', 'Answer.explanation', 'Worker.profession', 'Worker.ID'])
    y_graduates_set = prepared_graduates_df['GroundTruth']

    X_undergraduates_set = prepared_undergraduates_df.drop(columns=['GroundTruth', 'TP', 'FP', 'TN', 'FN', 'Answer.explanation', 'Worker.profession', 'Worker.ID'])
    y_undergraduates_set = prepared_undergraduates_df['GroundTruth']

    dtc = train_classifier(X_undergraduates_set, y_undergraduates_set)

    y_pred = dtc.predict(X_graduates_set)
    report = classification_report(y_graduates_set, y_pred, output_dict=True)
    print(report)

    zeros_precision.append(report['0']['precision'])
    ones_precision.append(report['1']['precision'])
    zeros_recall.append(report['0']['recall'])
    ones_recall.append(report['1']['recall'])

    for i in range(len(shuffled_prepared_non_students_df)):
        # Append the i-th row to the X_test_set
        X_new_row = X_shuffled_prepared_non_students_df.iloc[i].to_frame().T
        y_new_row = y_shuffled_prepared_non_students_df.iloc[i]

        X_undergraduates_set = pd.concat([X_undergraduates_set, X_new_row], ignore_index=True)
        y_undergraduates_set = pd.concat([y_undergraduates_set, pd.DataFrame([y_new_row])], ignore_index=True)

        y_pred = dtc.predict(X_undergraduates_set)
        report = classification_report(y_undergraduates_set, y_pred, output_dict=True)

        zeros_precision.append(report['0']['precision'])
        ones_precision.append(report['1']['precision'])
        zeros_recall.append(report['0']['recall'])
        ones_recall.append(report['1']['recall'])

    plt.style.use('tableau-colorblind10')
    plt.title("Precision and Recall Degredation with more non-students")
    plt.xlabel("Non-Students Samples in Test Set")
    plt.ylabel("Precision and Recall")

    plt.plot(np.arange(len(zeros_precision)), zeros_precision, label='Zeros Precision')
    plt.plot(np.arange(len(ones_precision)), ones_precision, label='Ones Precision')
    plt.plot(np.arange(len(zeros_recall)), zeros_recall, label='Zeros Recall')
    plt.plot(np.arange(len(ones_recall)), ones_recall, label='Ones Recall')
    plt.legend()
    #plt.show()

def minimal_needed_explanations(df: pd.DataFrame) -> int:
    thinker = Thinker()

    explanation_complexity_method = thinker.score_explanation
    df = pd.read_csv(ANSWERS_FILE)

    methods = df['FailingMethod'].unique().tolist()

    for method in methods[:1]:
        method_df = df[df['FailingMethod'] == method]
        _prepared_method_df = prepare_data(method_df, explanation_complexity_method, "needed_explanations")
        prepared_method_df = _prepared_method_df[['Answer.explanation', 'Answer.explanationComplexity']].sort_values(by='Answer.explanationComplexity', ascending=False)

        scores = prepared_method_df['Answer.explanationComplexity'].tolist()
        scores.sort()

        plt.style.use('tableau-colorblind10')
        plt.title("Explanation Complexity Score by GPT-4o")
        plt.xlabel("Explanation Index")
        plt.ylabel("Complexity Score")
        plt.plot(scores)
        plt.savefig(f"./complexity_scores_{method.lower().replace(' ', '_')}.png")

        print(f"Thinking used {thinker.used_tokens} tokens")
    
        # First two explanations that scored the best
        print("Merging together explanations...")
        scores = []
        
        for idx in range(2, 50):
            explanations = prepared_method_df.iloc[:idx].apply(lambda row: row['Answer.explanation'], axis=1).tolist()
            merged_explanation = thinker.merge_explanations(explanations)
            merged_explanation_score = explanation_complexity_method(explanation=merged_explanation)
            scores.append(merged_explanation_score)

            f = open(f"./{method.lower().replace(' ', '_')}_merged_explanations.txt", "a")
            f.write(f"# Merged Explanation {idx}\nScore: {merged_explanation_score}\n\n{merged_explanation}\n\n")
            f.close()

        plt.style.use('tableau-colorblind10')
        plt.title("Explanation Complexity Score by GPT-4o")
        plt.xlabel("Number of Explanations merged")
        plt.ylabel("Complexity Score")
        plt.plot(scores)
        plt.savefig(f"./complexity_scores_{method.lower().replace(' ', '_')}.png")

if __name__ == "__main__":
    minimal_needed_explanations(pd.read_csv("./data/answerList_data.csv"))
