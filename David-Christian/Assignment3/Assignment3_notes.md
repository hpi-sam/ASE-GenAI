# ASE Assignment 3

## Task 1

- split dataset into students and non-students
- split students dataset into test and holdout sets
    - both with the same percentage of GroundTruth entries
- on holdout set precision high, recall low
    - ~.22 with tuner at 10 trials (precision at 1.0)
    - ~.45 with tuner at 30 trials (precision at 1.0)
    - ~.45 with tuner at 100 trials (precision at 1.0)

### Adding non-students to holdout set

- adding 10 random non-students 150 times
    - precision remained at 1.0 during the entire run
    - recall increased to ~.53 initially, as high as ~.55, and then stayed roughly stable around ~0.51

### Adding non-students for training

- adding 100 non-students and then splitting into train and test sets
    - train and test sets are randomly created during each run
    - same percentage of GroundTruth entries in test and holdout set
- 16 runs total
    - precision stays at or close to 1.0
    - recall climbs steadily
- performance much better than trained model of previous task
    - probably because we do not split by method and can make sure that both test and holdout set contain the same ratio of correct GroundTruth entries

## Task 2

`HIT01_8` ground truth explanation:

The specification states, that the method "DateTimeZone()" accepts a minutes offset value in the range of -59 to 59 inlcusive. The method checks if this value, stored as "minutesOffset", is within these bounds on line 279, but incorrectly throws an "IllegalArgumentException" for any minutes offset less than zero instead of less than -59. To fix the issue and satisfy the specification, the conditional on line 279 should check for "minutesOffset < -59" instead.

LLM: `deepseek-llm`

### Readability and semantic similarity threshold

Readability should be in a range of +-5 or +-10 of our ground truth explanation, meaning the readability/complexity of the text should be similar to ours.

The (Bleurt) semantic similarity score should be as high as possible. Bleurt scores are between 0 and 1, a similarity of 80%, i.e. 0.8 would, would be desirable. The highest measured Bleurt score is 0.48, however, with most scores being reliably above 0.4. The few outliers that drop below this threshold are all instances, where the output of the llm did not meet our format expectations.

For this reason the 10th explanation probably meets our threshhold best, with a readability score similar to our ground truth and a relatively high Bleurt score of 0.46. After manual inspection we can also verify that the explanation is similar to ours, contains the required information, but is worded differently, which explains the Bleurt score.