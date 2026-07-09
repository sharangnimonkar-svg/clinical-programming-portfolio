"""
test_agent.py
=============
Runs 3 example clinical queries through the ClinicalTrialDataAgent
and prints a formatted summary of each result.

Usage:
    python test_agent.py

Optional — set your OpenAI key to use the real LLM:
    set OPENAI_API_KEY=sk-...        (Windows Command Prompt)
    $env:OPENAI_API_KEY="sk-..."     (Windows PowerShell)

Without a key the agent automatically uses the built-in Mock LLM,
which demonstrates the full Prompt -> Parse -> Execute flow.
"""

import os
import pandas as pd
from agent import ClinicalTrialDataAgent

# ---------------------------------------------------------------------------
# Load dataset
# ---------------------------------------------------------------------------

DATA_PATH = os.path.join(os.path.dirname(__file__), "adae.csv")
df = pd.read_csv(DATA_PATH, low_memory=False)

# ---------------------------------------------------------------------------
# Initialise agent
# ---------------------------------------------------------------------------

agent = ClinicalTrialDataAgent(dataframe=df)

# ---------------------------------------------------------------------------
# Define 3 test queries
# ---------------------------------------------------------------------------

TEST_QUERIES = [
    # Q1 — maps to AESEV
    "Give me subjects who had adverse events of Moderate severity.",

    # Q2 — maps to AEDECOD (specific condition)
    "Which patients experienced Nausea during the trial?",

    # Q3 — maps to AESOC (body system)
    "Show me all subjects with adverse events related to the Gastrointestinal system.",
]

# ---------------------------------------------------------------------------
# Run and print results
# ---------------------------------------------------------------------------

SEPARATOR = "=" * 65

print(f"\n{SEPARATOR}")
print("  CLINICAL TRIAL GenAI DATA ASSISTANT — TEST RESULTS")
print(SEPARATOR)

for i, question in enumerate(TEST_QUERIES, start=1):
    result = agent.ask(question)

    print(f"\nQuery {i}: {result['question']}")
    print(f"  → Mapped column : {result['target_column']}")
    print(f"  → Filter value  : {result['filter_value']}")
    print(f"  → Reasoning     : {result['reasoning']}")

    if "error" in result:
        print(f"  ✗ ERROR: {result['error']}")
    else:
        print(f"  → Subject count : {result['subject_count']}")
        # Print limit 100 IDs 
        ids = result["unique_usubjids"]
        preview = ids[:100]
        more = f"  ... and {len(ids) - 100} more" if len(ids) > 100 else ""
        print(f"  → Subject IDs   : {preview}{more}")

    print(f"  {'-' * 60}")

print(f"\n{SEPARATOR}")
print("  All queries completed.")
print(SEPARATOR)
