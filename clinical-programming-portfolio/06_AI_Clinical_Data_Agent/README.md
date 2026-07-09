# Clinical Trial GenAI Data Assistant

A natural language agent that translates free-text clinical questions into structured Pandas queries using an LLM (OpenAI GPT-3.5 via LangChain), with an automatic Mock LLM fallback if no API key is available.

\---

## Project Structure

```
06_AI_Clinical_Data_Agent/
├── agent.py          # ClinicalTrialDataAgent class
├── test_agent.py     # 3 example queries test script
├── adae.csv          # ADAE source data (place in the same directory)
├── requirements.txt  # Python dependencies
└── README.md
```

\---

## Prerequisites

* Python **3.9+** — download from https://www.python.org/downloads/windows/

  * During installation, tick **"Add Python to PATH"**
* `pip` is included with Python on Windows

\---

## Installation & Running (Windows PowerShell)

**1. Navigate to the project folder**

```powershell
cd clinical-programming-portfolio\06_AI_Clinical_Data_Agent
```

**2. Allow PowerShell to run local scripts (one-time setup)**

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Press **Y** then **Enter** when prompted.

**3. Create a virtual environment**

```powershell
python -m venv venv
```

**4. Activate the virtual environment**

```powershell
.\\venv\\Scripts\\Activate.ps1
```

You should see `(venv)` at the start of your prompt.

**5. Install dependencies**

```powershell
pip install -r requirements.txt
```

**6. Run the test script**

```powershell
python test_agent.py
```

> \*\*Note:\*\* `adae.csv` must be in the same folder as `agent.py` and `test\_agent.py`.

\---

## OpenAI API Key (Optional)

If you have an OpenAI API key, set it before running to use the real LLM:

```powershell
$env:OPENAI\_API\_KEY="sk-your-key-here"
python test_agent.py
```

Without a key, the agent automatically uses the built-in **Mock LLM** — a keyword-based fallback that demonstrates the full **Prompt → Parse → Execute** flow without any external service.

\---

## How It Works

```
User Question (free text)
      ↓
LLM receives question + dataset schema as context
      ↓
Returns structured JSON:
  { "target\_column": "AESEV", "filter\_value": "MODERATE", "reasoning": "..." }
      ↓
Pandas filter applied to ADAE DataFrame
      ↓
Result: { subject\_count, unique\_usubjids }
```

\---

## Column Mapping (Schema passed to LLM)

|Column|Clinical meaning|Example values|
|-|-|-|
|AESEV|Severity / intensity of the AE|MILD, MODERATE, SEVERE|
|AETERM|Verbatim AE term from subject|HEADACHE, NAUSEA|
|AEDECOD|MedDRA preferred term|HEADACHE, NAUSEA|
|AESOC|MedDRA System Organ Class|CARDIAC DISORDERS, GASTROINTESTINAL DISORDERS|
|AESER|Serious AE flag|Y, N|
|AEREL|Causality / relatedness to study drug|NONE, REMOTE, POSSIBLE, PROBABLE|
|ACTARM|Treatment arm|Placebo, Xanomeline High Dose|

**Synonym mappings understood by the agent:**

* "severity", "intensity", "grade" → AESEV
* "condition", "event", "term", specific AE names → AETERM / AEDECOD
* "body system", "organ class", "cardiac", "gastro" → AESOC
* "serious", "SAE" → AESER
* "causality", "probable", "possible" → AEREL
* "treatment", "arm", "placebo", "high dose" → ACTARM

\---

## Example Output

```
\[Agent] LLM mode: Mock LLM (no API key set)

=================================================================
  CLINICAL TRIAL GenAI DATA ASSISTANT — TEST RESULTS
=================================================================

Query 1: Give me the subjects who had adverse events of Moderate severity.
  → Mapped column : AESEV
  → Filter value  : MODERATE
  → Reasoning     : Question mentions severity keyword and value 'MODERATE'.
  → Subject count : 136
  → Subject IDs   : \['01-701-1023', '01-701-1047', ...] ... and 126 more
  ------------------------------------------------------------

Query 2: Which patients experienced Nausea during the trial?
  → Mapped column : AEDECOD
  → Filter value  : NAUSEA
  → Reasoning     : Question mentions a specific AE term 'nausea'.
  → Subject count : 12
  → Subject IDs   : \['01-701-1275', '01-701-1363', ...] ... and 2 more
  ------------------------------------------------------------

Query 3: Show me all subjects with adverse events related to the Gastrointestinal system.
  → Mapped column : AESOC
  → Filter value  : GASTROINTESTINAL DISORDERS
  → Reasoning     : Question mentions body system keyword 'gastro'.
  → Subject count : 53
  → Subject IDs   : \['01-701-1015', '01-701-1047', ...] ... and 43 more
  ------------------------------------------------------------

=================================================================
  All queries completed.
=================================================================
```

\---

## Design Notes

* **Schema-first approach**: the full column dictionary is injected into every LLM prompt so the model understands clinical terminology without hard-coded rules.
* **Mock LLM**: covers all synonym mappings (severity, body system, AE term, causality, treatment arm) so the complete pipeline is always demonstrable.
* **Priority ordering**: body system keywords (AESOC) are checked before causality keywords (AEREL) to prevent ambiguous words like "related" from misfiring.
* **Case-insensitive matching**: all string columns are normalised to uppercase at load time.

