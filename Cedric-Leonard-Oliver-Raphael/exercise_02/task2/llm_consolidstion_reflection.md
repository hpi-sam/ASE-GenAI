# Consolidating Bug Explanations with an LLM

We performed a series of experiments using a LLM to merge multiple programmer-provided bug explanations into a single concise explanation. We focused on minimizing redundant information while preserving details needed to fix the bug. Specifically, we filtered the data to retain relevant answers (True Positives and True Negatives) and grouped them by `Question.ID`. Each batch of explanations was then consolidated by the LLM according to one of three prompt variations. The prompt templates focus on a different level of detail and conciseness.

We then compared each original human answer to the LLM’s output using BLEU and ROUGE metrics. These metrics helped us quantify how much overlap there was between the LLM-generated text and the individual human responses. It should be noted that low BLEU scores can arise when the LLM paraphrases rather than copy exact phrases.

Looking at the results the model sometimes omitted small but important details, or conversely introduced information that was not fully verified. Moreover, depending on the prompt variation, the LLM’s style and level of specificity changed significantly. Through manual prompt engineering, we could better guide the LLM to maintain crucial points while trimming irrelevant or redundant content. Consolidating bug explanations with an LLM shows promise, but the final summaries should always be reviewed by human experts to ensure correctness and completeness, especially in more complex or domain-specific bug reports.

# Reflection Questions

## 1. Quality of the data

- The quality of answers among participants may vary significantly, which is inherent to surveys with free-text fields. Factors like the effort each participant invests, their skill level, and mood contribute to this variability.
- Answer options such as "yes," "no," or "I don’t know" may not be precise enough for all participants. For instance, participants may dislike the coding style and thus exhibit a negative bias in their responses.
- When using survey results, it is crucial to understand the exact procedure followed during the survey, including how participants were briefed, the time allocated, and the selection process. Without this information, the data lacks context, which poses a significant challenge for data science applications.
- Even if the develop answer matches the ground truth there it is not garanteed that the content from the answer explanation is correct

## 2. Keeping the classifier up-to-date in the case of changes in the demographic of programmers or types of bugs

- The dataset is relatively small for data science tasks. Adding more data, such as diverse bug types or records of new programmers, can help optimize the classification performance of models like random forests. However, the quality of the new data entries and the context in which features are selected are critical considerations (see point 1 regarding missing context).
- In case of larger datasets rerunning the complete training can be too expensive (time-wise and financially). The model could be fine-tuned with newer data e.g. by pruning the tree and then only training the pruned tree or more advanced tree-based approaches e.g. XGBoost (freeze lower layers in MLP during retraining with new data.)

## 3. Testing the output of the classifier and the LLM

- For the LLM: Metrics like ROUGE and BLEU provide an initial impression of output quality, but use-case-specific metrics combined with human evaluation (ideally involving a majority vote from experts) would yield more precise and actionable insights.
- For the Random Forest: It is essential to consider feature selection and feature importance during evaluation. This requires well-defined research questions, which should guide careful feature selection to ensure meaningful results.

## 4. Estimating the quality of the consolidated explanations

- The quality of bug reports is subjective and depends on the skill levels and development styles of those evaluating them.

- Metrics like ROUGE and BLEU may lead to misleading assessments of quality. These scores rely on word-level comparisons between reference and candidate outputs, overlooking the true semantic meaning. Factors such as the use of synonyms, varying vocabulary richness, or differences in writing styles (e.g., bullet points vs. full sentences) can heavily skew the results. This introduces a potential bias, as LLM outputs compared to a native speaker’s answer may receive disproportionately higher quality rankings.

## 5. Debugging the integration between the classifier and the LLM

- Debugging the random forest model is relatively transparent, as feature importances and decision thresholds can be computed and analyzed.
- Debugging the LLM is more challenging due to its "black-box" nature. Small adjustments to the phrasing or wording of prompts can result in significantly different outputs.
- For any AI application, it is crucial to understand the classifier’s decision-making process. Merely evaluating the LLM’s output without analyzing the reasoning behind the classifier’s decisions can lead to misleading conclusions.
