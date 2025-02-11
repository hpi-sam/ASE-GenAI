import os
import time
from typing import Literal
import ollama
from openai import OpenAI
from dotenv import load_dotenv
import re

class Thinker:
    def __init__(self):
        load_dotenv()
        self.OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
        self._used_tokens = 0

    def prompt_openai(self, messages: list[dict[str, str]], model: Literal["gpt-4o", "gpt-4o-mini", "gpt-4"]) -> tuple[str, int]:
        client = OpenAI(api_key=self.OPENAI_API_KEY)
        response = client.chat.completions.create(
            model=model,
            messages=messages
        )
        return response.choices[0].message.content, response.usage.total_tokens

    def think(self, prompt: str) -> str:
        time.sleep(0.2) # Due to rate limiting

        SCORE_SYSTEM_PROMPT = """
# Instructions

You are an expert bug description summarizer. You are employed by a company that collects bug reports from users.
However, you must never make up any information.

Your task is to summarize the bug reports. You always answer in English. Act like you'd be a human expert software developer explaining the bug to another human.

Think step-by-step to summarize the bug report.
1. Is the bug report already good as it is? If so, return "Good as it is".
2. Is the bug report providing so little information that it is not useful? If so, return "Not useful".
3. If not: perform the following steps:
    - Read the bug report carefully.
    - Summarize the bug report in a few sentences. Use your knowledge about coding to add missing information.
    - Return the summary.
""".strip()

        response = self.prompt_openai(
            messages=[
                {"role": "system", "content": SCORE_SYSTEM_PROMPT},
                {"role": "user", "content": prompt}
            ],
            model="gpt-4o"
        )

        self._used_tokens += response[1]
        return response[0].strip()

    def get_score(self, prompt: str) -> str:
        THINK_SYSTEM_PROMPT = """
# Instructions

You are an expert bug description scorer. You are employed by a company that collects bug reports from users.
Your task is to score the bug reports. The only thing you should answer is a number between 0 and 100.

- 0 means the bug report is not useful at all.
    - Examples:
        - "I don't know"
        - "No idea"
        - "Not my job"
- 50 means the bug report contains some useful information, that developers can use to fix the bug.
    - Examples:
        - "The bug is about a missing semicolon."
        - "The function 'set_user_name' does not work properly."
- 100 means the bug report is very useful.
    - Examples:
        - "The bug is on line 102, where the variable is missing a semicolon."
        - "The bug is in the function 'calculate_total_price', where the variable 'tax' is not defined."
""".strip()

        response = self.prompt_openai(
            messages=[
                {"role": "system", "content": THINK_SYSTEM_PROMPT},
                {"role": "user", "content": prompt}
            ],
            model="gpt-4o"
        )

        self._used_tokens += response[1]
        return response[0].strip()

    def score_explanation(self, explanation: str, stdout: bool = False, prompt_id: str | None = None) -> int:
        if prompt_id:
            try:
                f = open(f"./prompts/{prompt_id}.txt", "r")
                explanation = f.read()
                print(f"Using cached explanation for {prompt_id}: {explanation}")
                return int(explanation)
            except FileNotFoundError:
                # Nothing to do here, as prompt has not been cached yet.
                pass
            except ValueError:
                raise ValueError(f"{explanation} is not a valid integer")

        last_result = explanation
        thinking_result = self.think(explanation)
        for i in range(0, 6):
            if "Good as it is" in thinking_result or "Not useful" in thinking_result:
                break
            last_result = thinking_result
            thinking_result = self.think(thinking_result)

        score = self.get_score(last_result)
        if stdout:
            print(f"{explanation} --> {last_result} (Score: {score}, Tokens: {self.used_tokens})")

        f = open(f"./prompts/{prompt_id}.txt", "w")
        f.write(score)
        f.close()

        return int(score)

    def merge_explanations(self, explanations: list[str]) -> str:
        MERGE_SYSTEM_PROMPT = """
# Instructions

You are an expert bug description merger. You are employed by a company that collects bug reports from users.
Your task is to merge the bug reports. You always answer in English.

However, you must never make up any information.

You should follow these steps:
1. Read the bug report carefully.
2. Summarize the bug report in a few sentences. Use your knowledge about coding to add missing information.
3. Return the summary.
""".strip()

        response = self.prompt_openai(
            messages=[
                {"role": "system", "content": MERGE_SYSTEM_PROMPT},
                {"role": "user", "content": f"""
# Given Explanations

{''.join([f'- Explanation {i+1}: {expl}' for i, expl in enumerate(explanations)])}
"""}
            ],
            model="gpt-4o"
        )
        return response[0].strip()

    @property
    def used_tokens(self):
        return self._used_tokens
