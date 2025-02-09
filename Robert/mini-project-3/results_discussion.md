<!-- Did you try looking at this in preview mode? -->

# Mini Project 3: Results Discussion

## Task 1: Distribution Shifts

Parameters taken from mini-project-2:

- Used Model: DecisionTreeClassifier from scikit-learn
    - No further tuning on model parameters
- Explanation Complexity Method: Number of words in the explanation
    - e.g., "The error is on line 10" --> 5 words

### Attempte 1.1: Graduates for Training, Undergraduates for Testing

- Spilt the dataset into 3 parts:
    - Undergraduates: Training set
    - Graduates: Testing set
    - Non-students: Testing set (one-by-one added to the training set)
- The classifier is solely trained on the graduates
- For the non-students, shuffle the dataset and calculate the precision and recall for the classifier

Following results are obtained:

![img](./img/task1-attemp1.png)

