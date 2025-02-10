# Task 1: Distribution shifts

We split the data in holdout set and training set in the same way we split it in Project2. 
This means Task 5 and 6 are part of the holdout set.
Precision:
Recall:

Now we gradually add random non-student answers


# Task 2: Necessary and Sufficient Explanations

For readability we chose the Flesch-Kincaid Reading Ease. This measurement was design for general text
and should roughly return a value between 100 and 0 where 100 is translated to
"Very easy to read. Easily understood by an average 11-year-old student." and 0 is translated to
"Extremely difficult to read. Best understood by university graduates.". In general this measurement 
punishes long words and long sentences.

We generate the ground truths using ChatGPT.
We provide ChatGPT with all true positive answers per task and the following prompt:

"The following {number of explanations} lines contain {number of explanations} correct explanations
for the same bug. I would like you to generate a single explanation that is as short and
concise as possible and at the same time contains the information that would be necessary for
another person to fix the bug. The text you create should be 3 to 5 sentences long,
with an emphasis on readability."

We use a new Chat for each task in order to provide equal conditions to ensure comparability.
The prompt is designed to generate equally long texts as we thought same text length would make the
Flesch-Kincaid Reading Ease more relevant.

The ground truths can be found in Groundtruth.txt

The Flesch-Kincaid Reading Ease for our ground truths are:
Task 1: 29.5
Task 2: 53.2
Task 3: 45
Task 4: 49.6
Task 5: 60.1
Task 6: 32
Task 7: 59.8
Task 8: 46.8

Our Flesch-Kincaid Reading Ease scores are between 30 and 60 where 30 translates
to "Very difficult to read. Best understood by university graduates." and 60 translates to 
"Fairly difficult to read.". This is around the level we expected as the data proves that these tasks
are so difficult that a lot of trained professionals were not able to solve them.
individuals w
