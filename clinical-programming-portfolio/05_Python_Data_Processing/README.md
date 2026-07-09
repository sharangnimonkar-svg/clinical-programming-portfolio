# Clinical Trial Data API

A RESTful API built with **FastAPI** that serves ADAE (Adverse Events Analysis Dataset) data, supports dynamic cohort filtering, and calculates patient safety risk scores.

---

## Project Structure

```
.
├── main.py       # FastAPI application
├── adae.csv      # ADAE source data (place in the same directory)
├── requirements.txt
└── README.md
```

---

## Prerequisites

- Python **3.9+** — download from https://www.python.org/downloads/windows/
  - During installation, tick **"Add Python to PATH"**
- `pip` is included with Python on Windows

---

## Installation & Running the API (Windows PowerShell)

Open PowerShell, navigate to the project folder, then follow these steps **in order**:

**1. Navigate to the project folder**
```powershell
cd clinical-programming-portfolio\05_Python_Data_Processing

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
.\venv\Scripts\Activate.ps1
```
You should see `(venv)` appear at the start of your prompt.

**5. Install dependencies (one-time setup)**
```powershell
pip install -r requirements.txt
```

**6. Start the API**
```powershell
uvicorn main:app --reload
```

The server is ready when you see:
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Application startup complete.
```

> **Note:** `adae.csv` must be in the same folder as `main.py`.  
> To stop the server, press **Ctrl + C**.  
> For subsequent runs, only steps 4 and 6 are needed.

---

## Testing the API

Once running, open your browser and go to:

```
http://127.0.0.1:8000/docs
```

This opens the **Swagger UI** — an interactive interface to test all endpoints without any extra tools.

---

## Endpoints

### `GET /`
Health check — confirms the API is running.

**Response:**
```json
{"message": "Clinical Trial Data API is running"}
```

---

### `POST /ae-query` — Dynamic Cohort Filter

Filter the ADAE dataset by **severity** and/or **treatment arm**.
Both fields are optional; omit or set to `null` to skip that filter.

**Request body:**
```json
{
  "severity": ["MILD", "MODERATE"],
  "treatment_arm": "Placebo"
}
```

**Response:**
```json
{
  "record_count": 293,
  "subject_count": 66,
  "unique_usubjids": ["01-701-1015", "01-701-1023", "..."]
}
```

---

### `GET /subject-risk/{subject_id}` — Patient Risk Score

Calculate a weighted **Safety Risk Score** for a specific subject.

| Severity  | Points |
|-----------|--------|
| MILD      | 1      |
| MODERATE  | 3      |
| SEVERE    | 5      |

| Category | Score range |
|----------|-------------|
| Low      | < 5         |
| Medium   | 5 – 14      |
| High     | ≥ 15        |

**Example response:**
```json
{
  "subject_id": "01-701-1015",
  "risk_score": 3,
  "risk_category": "Low"
}
```

Returns **HTTP 404** if the subject ID does not exist.

---

## Design Notes

- **Data normalisation**: `AESEV` and `ACTARM` are uppercased at load time so filtering is case-insensitive for callers.
- **Missing severities**: AE records with unrecognised or missing `AESEV` values contribute 0 points to the risk score rather than raising an error.
- **No database required**: the CSV is loaded into a Pandas DataFrame at startup, appropriate for this dataset size (~1,000 rows).
