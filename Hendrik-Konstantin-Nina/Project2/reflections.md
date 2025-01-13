# Specifications - II

### Reflection question:

Choosing a complexity measure

**TTR:**
The issue lies in aissigning high complexity ratings to fields that only contain one word, even if this word is arbitrary chosen.

**Halstead:**
V=N⋅log(n) N: Total number of words; n: Number of unique words
Halstead just looks at unique words and sets it into relation to the overall number of words.
Therefore, no consideration of sentence structure or used words is taken into account.

**Margalef:**
D=(S−1)/ln(N) S: Number of unique words; N: Total number of words
Like Halstead, Margalef also looks at unique words and sets it into relation to the overall number of words, resulting in the same disadvantages.

**Flesch reading ease**
206.835 - 1.015 _ (total words / total sentences) - 84.6 _ (total syllables / total words)
Flesch Reading Ease focuses on readability by analyzing sentence length and syllables per word.
It helps determine how easy a text is to understand for readers.
Our assumption is that a more complex answer will show more knowledge about the topic.

Given the reasoning above, we have decided to use Flesch reading ease as a complexity metrix.

Each measure however, just looks at unique words and sets it into (a different) relation to the overall number of words. This may lead to a bias towards higher complexity scores for participants who speak English natively and also does not entail capturing the true meaning of the given answers.

### Reflection question:

"Try different ways of prompting and report on how the size and complexity of explanations changed."

### Answer:

We tried out different ways of prompting:

1. Using the task from our task description in a slightly adapted form

   **Outcome:** The answers provided were really long, including the precise code snippets. We had to prompt multiple times in order to match the format of the participants of the survey. We were then able to prompt the LLM again with different data ("Can you do this again for the data below?") and received an answer in the same format.

2. Letting the LLM first imagine to be a programmer being part of the survey, then asking to consolidate the answers.
   **Outcome:** The answers provided were rather long, not similar to the format of the answers of the study participants.

3. Giving the LLM the precise role to be a developer who consolidates bug reports.

   **Outcome:** We had to prompt the LLM twice as the first answer was too long. Providing a max. number of phrases (3) in the next prompt gave a good explanation. After doing it twice correctly, the LLM jumped back to the long format for the third set of answer data provided.

4. Giving the LLM the precise role to be a developer who consolidates bug reports and also a rough performance measure of their work. We did not name the max. number of phrases specifically as we wanted to see if the LLM could still provide a short, yet correct solution.

   **Outcome:** This worked great, using only one prompt. However, prompting again with different data let yet to another really long answer, not similar to the given setting.

**Complexity (TTR) and Consolidation Quality:**

| HIT file | LLM_technique_id | LLM_technique_desc                                           | TTR      | BLEU   | ROUGE-1 | ROUGE-2 | ROUGE-L |
| -------- | ---------------- | ------------------------------------------------------------ | -------- | ------ | ------- | ------- | ------- |
| HIT01_8  | 1                | original task and additional prompting                       | 0.837838 | 0.5592 | 0.2584  | 0.0425  | 0.1754  |
| HIT02_24 | 1                | original task and additional prompting                       | 0.709302 | 0.2887 | 0.2394  | 0.0265  | 0.1526  |
| HIT03_6  | 2                | letting llm imagine to be study participant first            | 0.614525 | 0.4436 | 0.1796  | 0.0355  | 0.1143  |
| HIT04_7  | 3                | llm role as programming buddy with fixed answer length       | 0.972222 | 0.2887 | 0.1467  | 0.0188  | 0.0887  |
| HIT05_35 | 3                | llm role as programming buddy with fixed answer length       | 0.846154 | 0.3717 | 0.2052  | 0.0306  | 0.1402  |
| HIT06_51 | 3                | llm role as programming buddy with fixed answer length       | 0.679012 | 0.3354 | 0.1891  | 0.0368  | 0.1370  |
| HIT07_33 | 4                | role as developer with performance (professionalism) measure | 0.771930 | 0.4488 | 0.2361  | 0.0698  | 0.1701  |
| HIT08_54 | 4                | role as developer with performance (professionalism) measure | 0.746667 | 0.5707 | 0.2239  | 0.0617  | 0.1367  |

**Avg. score per prompting technique**

| Prompting technique                                             | BLEU   | ROUGE-1 | ROUGE-2 | ROUGE-L |
| --------------------------------------------------------------- | ------ | ------- | ------- | ------- |
| 1: original task and additional prompting                       | 0.4239 | 0.2489  | 0.0345  | 0.1640  |
| 2: letting llm imagine to be study participant first            | 0.4436 | 0.1796  | 0.0355  | 0.1143  |
| 3: llm role as programming buddy with fixed answer length       | 0.3319 | 0.1803  | 0.0288  | 0.1220  |
| 4: role as developer with performance (professionalism) measure | 0.5097 | 0.2300  | 0.0658  | 0.1534  |

Looking at the scores per prompting technique, we can observe:

1. Original task with additional prompting (Technique 1):

   - Shows good overall performance with balanced BLEU (0.4239) and highest ROUGE-1 (0.2489) scores
   - This suggests that keeping close to the original task format while guiding the LLM with additional prompts produces reliable and comprehensive consolidations

2. LLM imagining to be study participant (Technique 2):

   - Has decent BLEU score (0.4436) but lower ROUGE scores across the board
   - While this approach helps the LLM understand the participant perspective, it seems to produce answers that deviate from the reference consolidations in terms of content and structure

3. Programming buddy with fixed length (Technique 3):

   - Shows the lowest performance across most metrics (BLEU: 0.3319, ROUGE-1: 0.1803)
   - This indicates that strictly limiting the answer length may force the LLM to omit important details, resulting in less accurate consolidations

4. Developer role with performance measure (Technique 4):
   - Achieves the highest BLEU score (0.5097) and strong ROUGE-2 score (0.0658)
   - This approach appears most effective, suggesting that giving the LLM a professional context and quality expectations leads to more precise and relevant consolidations

---

What are the concerns about:

1. **guaranteeing the quality of the data**
   - the answer explanation given by the study participants does not need to align with the tick (yes, no, i dont know [there is a bug in the code]) they have made wether or not there is a bug in the given code snippet; even if the tick is classified as true positive, their answer explanation might not be correct
   - the choice yes-no-i don't know might be correct just by chance
   - the choice yes/no is taken because the developer overestimates their Java abilities
   - the whole survey needs to be conducted correctly (e.g. all people need to have the same setup, no access to LLMs, people randomly chosen, ...)
2. **keeping the classifier up-to-date in the case of changes in the demographic of programmers or types of bugs**

   - if more demographic features are added (and available for the old entries as well) or if new entries are added to the dataset, a retraining has to be conducted to retrain the classifier
   - as the data set given is really small; training the model from anew should not be an issue
   - in case of larger data set, this could become an issue due to the training time/costs

3. **testing the output of the classifier and the LLM**

   - The classifier heavily relied on the complexity score. However, choosing the right complexity score is challenging. For example, TTR measures the relation between number of unique words to the overall number of words in an answer. Yet, if only one word was given, the score returned is 1, representing a high lexical diversity.
   - to use the complexitiy measure as a metrix does often not determine wether or not an answer given is correct or not

4. **estimating the quality of the consolidated explanations**
   - using ROUGE or BLEU as a measure of quality may lead to incorrect estimations; these scores compare the words of the reference and candidate answers, and therefore do not take true meanings into account; using synonyms, are higher or lower variety of words, writing in bullet points vs. full sentences therefore highly influence the ROUCE and BLEU scores
   - this might also lead to a bias such that comparing the LLMa answer to a native speaker's answer receive higher quality ranking
   - a short and precise answer might be penalized using BLEU or ROUGE
   - the quality is rather a subjective measure. For example, more information to fix a bug might be helpful for junior developers. On the other hand, senior developers might be more torn towards the shortest answer possible to save time. Finding the correct quality measure should always be put in context.
   - instead, embeddings could be used to calculate a better quality score; we propose embeddings that capture the overall meaning of each answer and compare it to the LLM consolidation; therefore we can achieve a better comparison of the true meanings
5. **debugging the integration between the classifier and the LLM**
   - debugging the interaction between the us, the developer, and the LLM is rather easy, because it is interactive and our prompt to consolidate the answers is considerably simple
   - the only data the LLM relies on can easily be prepared by the developer
   - debugging how an LLM derives it's answer is intransparent, as the LLM can be seen as a black box
   - debugging the classifier is more transparent and can easily visualized, e.g. by plotting feature importances
   - data preparation takes the most resources and is harder to debug than the code necessary to simply create the LLM input data
