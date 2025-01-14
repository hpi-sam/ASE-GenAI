# Specifications I - Implementing & Reflecting on the Classifier
This file documents our classifier approach and reflects on its results regarding the task of detecting correct bug explanations.

## Preparing the Data
For the answers textual information we decided to use a variation of the proposed TTR (type-token-ratio), namely the root type-token-ratio (RTTR).
It is quite similar to its base version but normalizes by text lengths in order to reflect a complexity metric that is not that heavily influenced by the length of the answer. [1]

For including information about the code samples that contained the bugs we also decided to follow the suggestion of the task description to use the Halstead volume metric [2].
But there are several other Halstead metrics that we employed (difficulty, length, effort, vocabulary). These all together supply use with an estimate how complex the code sample was which contained the bugs.
These metrics were collected with use of the "MetricsReloaded" Plugin for the IntelliJ IDE [3]. We configured the plugin to evaluate the Halstead metrics based on the classes contained in the provided Java-based source code files.
In one case, there were two classes in the same file ([`../data/HIT01_8.java`](./data/HIT01_8.java)), for which we used the average Halstead metrics over both of the classes.
The collected metrics can be found in the [`../data/halstead_volumes.csv`](./data/halstead_volumes.csv) file.

[1] https://www.sketchengine.eu/glossary/type-token-ratio-ttr/<br/>
[2] http://www.virtualmachinery.com/sidebar2.htm<br/>
[3] https://plugins.jetbrains.com/plugin/93-metricsreloaded


## Training the Model
We conducted a series of experiments while training the employed model choice, a random forest classifier.

### Target Variable
First things first, we needed to find which variable to predict and thought that "GroundTruth" would be it. We conducted many experiments using different engineered train features with this setting and ran into problems regarding model performance. We only achieved an average test precision of ~0.51 and test recall of ~0.23 in the most promising feature constellation, making us question the usability of the RF model in this context.

Finally, we realized that our prediction target was wrong and that "Answer.option" == "GroundTruth" should be predicted. With this, we instantly received precision > 0.7 and recall > 0.9, see [`./exercise_02/task1/results/one_test_set/experiment.log`](./exercise_02/task1/results/one_test_set/experiment.log).

These log files report on the precision and recall metrics gathered during the 5-fold cross validation process based on the remaining 6 code samples.
Additionally, also the test precision and recall metrics are shown for each permutation of the two holdout sets. Over all permutations of holdout sets for testing, we also output an average test precision and recall.

While experimenting, we noticed that there are certain permutations of the 2 holdout sets that result in rather bad recall and precision im comparison.
This is because just using two fixed test FailingMethods is not robust enough since the two methods might be particularly easy or hard to predict. Therefore, we ran an experiment where we used all different permutations of two FailingMethods as test, which can be seen in [`./exercise_02/task1/results/all_test_sets/evaluation_metrics_grouped.png`](./exercise_02/task1/results/all_test_sets/evaluation_metrics_grouped.png). We do indeed see differences in performance for some FailingMethods, confirming our suspection.

This plot also shows us that our model is indeed overfitting on the train set. We tried to mitigate that via the hyperparamters of the model, e.g. choosing a different number of trees or a higher `min_samples_split`. But these methods only decreased test performance as well, so we just let the model choose its best parameters via `GridSearch`.

## Further reflection tasks
### Guaranteeing the Quality of the Data and Keeping the Classifier up-to-date.
It is fair to say we used much of our time investigating relevant features and metrics that we should rely on during training.
As soon as new or updated data comes in, we think our approach would need equivalent preprocessing steps in order to collect the relevant metrics.
For example, for calculating the different Halstead metrics IntelliJ was especially helpful because of the fact the source code was written in Java.
It is debatable how it would perform on computing the metrics for other programming languages.

### Testing the Output of the Classifier
Repeatedly evaluating on the employed features and their importances is crucial in order to detect overfitting and possibles biases.
Feature importance plots are quite a valuable technique in order to do so in combination with comparing precision and recall metrics.
Also, that is something that needs to be monitored when new data comes in or previous data changes.

Reading and understanding code and related explanations might be quite subjective though and does the question of identifying code bugs and understanding related explanations really drill down to objectively measurable features?

### Debugging the Classifier and LLM in combination
Even though we didn't build a pipeline between classifier outputs and the consolidation task with the LLM,
we would argue that debugging this pipeline could be quite tricky.

Since the RF output is not 100% perfect, the LLM would not have that much of a great set of actual answers to consolidate in the first place,
which heavily influences the LLM's result.

On the other hand, if the consolidated answer from the LLM isn't really helpful at all, at this point of time most developers would blame it on the LLM. :D
This is magnified by the fact that LLMs are currently a very black box under the hood, while tree-based methods are still explainable via feature importance and decision rules e.g.
