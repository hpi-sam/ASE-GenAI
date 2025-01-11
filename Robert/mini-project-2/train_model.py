from glob import glob
import os
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import classification_report, confusion_matrix
import numpy as np
from openai import OpenAI
import time

from dotenv import load_dotenv

OPENAI_API_KEY = load_dotenv()

ANSWERS_FILE = "./data/answerList_data.csv"
CODE_FILES = glob("./data/*.java")

models = {
    "gpt-4-mini": {
        "model": "gpt-4o-mini",
        "cost_per_million_tokens": 0.15
    },
    "gpt-4": {
        "model": "gpt-4o",
        "cost_per_million_tokens": 2.5
    },
}

USED_MODEL = models.get("gpt-4-mini")

def calculate_costs(model, used_tokens: int):
    return (used_tokens / 1_000_000) * model.get("cost_per_million_tokens")

def openai_explanation(text, model):
    role = """
        1. You are a developer that explains code to developers. Your task is to fix bugs. If you cannot fix the bug from the information available to you, say it!
        2. Don't say that you are going to give an answer now, but give the answer straight away. I want to act like a human answered this not a machine. 
    """

    client = OpenAI(api_key=OPENAI_API_KEY)
    response = client.chat.completions.create(
        model=model.get('model'),
        messages=[
            {"role": "system", "content": role},
            {"role": "user", "content": text}
        ]
    )
    return response.choices[0].message.content, response.usage.total_tokens


def number_of_words(expl, _method):
    return len(expl.split(" "))


def halstead_complexity(expl, method):
    # Split explanation into words
    words = open(f'./data/{method}.java', "r").read().split()
    
    # Define common operators (you can expand this list)
    operators = {'if', 'then', 'else', 'while', 'for', 'and', 'or', 'not', 
                'is', 'are', 'was', 'were', 'because', 'therefore', 'thus',
                'hence', 'so', 'since', 'due'}
    
    # Count unique and total operators/operands
    n1 = len(set(w.lower() for w in words if w.lower() in operators))  # unique operators
    n2 = len(set(w.lower() for w in words if w.lower() not in operators))  # unique operands
    N1 = sum(1 for w in words if w.lower() in operators)  # total operators
    N2 = sum(1 for w in words if w.lower() not in operators)  # total operands
    
    # Avoid division by zero
    if n1 == 0 or n2 == 0:
        return 0
        
    # Calculate Halstead metrics
    program_length = N1 + N2
    vocabulary = n1 + n2
    volume = program_length * np.log2(vocabulary)
    difficulty = (n1 * N2) / (2 * n2)
    effort = difficulty * volume
    
    return effort  # Return effort as the complexity measure


parameters = [
    {
        'criterion': 'entropy',
        'ccp_alpha': 0.004,
        'random_state': 69,
        'test_size': 20,
        'explanation_complexity_method': number_of_words,
        'outfolder': 'number_of_words-ccp-alpha-0.004'
    },
    {
        'criterion': 'gini',
        'ccp_alpha': 0,
        'random_state': 42,
        'test_size': 20,
        'explanation_complexity_method': number_of_words,
        'outfolder': 'number_of_words'
    },
    {
        'criterion': 'entropy',
        'ccp_alpha': 0,
        'random_state': 42,
        'test_size': 20,
        'explanation_complexity_method': halstead_complexity,
        'outfolder': 'halstead-complexity'
    }
]

def main():
    #[train_model(params) for params in parameters]
    train_model(parameters[1])

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
    methods_raw = df['FailingMethod'].tolist()

    explanation_complexities = []
    for i in range(len(explanations_raw)):
        expl = explanations_raw[i]
        method = methods_raw[i]
        explanation_complexities.append(explanation_complexity_method(str(expl), method))

    df['Answer.explanationComplexity'] = explanation_complexities

    jobs = df['Worker.profession'].unique().tolist()
    genders = df['Worker.gender'].unique().tolist()
    countries = df['Worker.country'].unique().tolist()
    answers = df['Answer.option'].unique().tolist()
    failing_methods = df['FailingMethod'].unique().tolist()
    where_learned_to_code = df['Worker.whereLearnedToCode'].unique().tolist()
    prepared_data = df.copy()

    prepared_data['Worker.profession'] = [jobs.index(job) for job in df['Worker.profession'].tolist()]
    prepared_data['Worker.profession'] = [genders.index(gender) for gender in df['Worker.gender'].tolist()]
    prepared_data['Worker.country'] = [countries.index(country) for country in df['Worker.country'].tolist()]
    prepared_data['Answer.option'] = [answers.index(answer) for answer in df['Answer.option'].tolist()]
    prepared_data['FailingMethod'] = [failing_methods.index(method) for method in df['FailingMethod'].tolist()]
    prepared_data['Worker.gender'] = [genders.index(gender) for gender in df['Worker.gender'].tolist()]

    prepared_data.to_csv(f"./out/{outfolder}/prepared_data1.csv")

    prepared_data['Worker.whereLearnedToCode'] = [score_for_where_learned_to_code(where_learned_to_code) for where_learned_to_code in df['Worker.whereLearnedToCode'].tolist()]
    prepared_data['Worker.programmingLanguage'] = [score_for_programming_languages(str(pl)) for pl in df['Worker.programmingLanguage'].tolist()]

    prepared_data.to_csv(f"./out/{outfolder}/prepared_data2.csv")
    return prepared_data

def train_model(parameters):
    df = pd.read_csv(ANSWERS_FILE)
    df = df.drop(columns=['Worker.ID'])

    if not os.path.exists(f"./out/{parameters['outfolder']}"):
        os.mkdir(f"./out/{parameters['outfolder']}")

    # Transforms all strings to numbers
    prepared_data = prepare_data(df, parameters['explanation_complexity_method'], parameters['outfolder'])

    test_set_size = parameters['test_size']
    test_set_ratio = test_set_size / len(df)

    X = prepared_data.drop(columns=['GroundTruth', 'TP', 'FP', 'TN', 'FN', 'Answer.explanation'])
    y = prepared_data['GroundTruth']

    X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=parameters['random_state'], test_size=test_set_ratio)

    dtc = DecisionTreeClassifier(criterion=parameters['criterion'], ccp_alpha=parameters['ccp_alpha'])
    dtc.fit(X_train, y_train)

    y_pred = dtc.predict(X_test)

    report = classification_report(y_test, y_test)
    with open(f"./out/{parameters['outfolder']}/report_for_training_set.txt", "w") as f:
        f.write(report)
    report = classification_report(y_test, y_pred)
    with open(f"./out/{parameters['outfolder']}/report_for_test_set.txt", "w") as f:
        f.write(report)
    
    features = pd.DataFrame(dtc.feature_importances_, index=X.columns, columns=['Importance']).sort_values(by='Importance', ascending=False)
    features.to_csv(f"./out/{parameters['outfolder']}/features-importance.csv")

    results = df[df['GroundTruth'] == 1]

    used_tokens = 0
    start = time.time()
    questions_merges = {}
    questions_ids = results['Question.ID'].unique().tolist()
    for id in questions_ids:
        questions = results[results['Question.ID'] == id]
        explanations = questions['Answer.explanation'].tolist()

        text = f"""
The following is a list of explanations for a question. Merge it to sensible text.
Only keep really relevant information. Make the answer as short as possible, but still informative.
'{"','".join(explanations)}'""".strip()

        questions_merges[id], total_tokens = openai_explanation(text, USED_MODEL)
        used_tokens += total_tokens

    print(used_tokens)
    print(f"Costs: {calculate_costs(USED_MODEL, used_tokens)}")
    end = time.time()

    print(f"Building Explanations took {(end - start):.2f}s")


if __name__ == "__main__":
    main()