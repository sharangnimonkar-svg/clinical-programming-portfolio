"""
Clinical Trial Data API
=======================
A FastAPI application that serves ADAE (Adverse Events Analysis Dataset) data,
supports dynamic cohort filtering, and calculates patient safety risk scores.
"""

import os
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict
from typing import List, Optional

# ---------------------------------------------------------------------------
# Application setup
# ---------------------------------------------------------------------------

app = FastAPI(
    title="Clinical Trial Data API",
    description=(
        "RESTful API for querying ADAE adverse event data, "
        "dynamic cohort analysis, and patient safety risk scoring."
    ),
    version="1.0.0",
)

# ---------------------------------------------------------------------------
# Load dataset at startup
# ---------------------------------------------------------------------------

DATA_PATH = os.path.join(os.path.dirname(__file__), "adae.csv")

try:
    df = pd.read_csv(DATA_PATH, low_memory=False)
    # Normalise key columns to uppercase strings for consistent matching
    df["AESEV"]   = df["AESEV"].astype(str).str.upper().str.strip()
    df["ACTARM"]  = df["ACTARM"].astype(str).str.upper().str.strip()
    df["USUBJID"] = df["USUBJID"].astype(str).str.strip()
except FileNotFoundError:
    raise RuntimeError(
        f"Could not find adae.csv at {DATA_PATH}. "
        "Place the file in the same directory as main.py."
    )

# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------

class AEQueryRequest(BaseModel):
    """
    Request body for POST /ae-query.

    Both fields are optional:
      - severity      : list of AESEV values to include  (e.g. ["MILD", "MODERATE"])
      - treatment_arm : ACTARM value to filter on         (e.g. "Placebo")

    Omit or set to null to skip that filter.
    """
    severity: Optional[List[str]] = None
    treatment_arm: Optional[str]  = None

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "severity": ["MILD", "MODERATE"],
                "treatment_arm": "Placebo",
            }
        }
    )


class AEQueryResponse(BaseModel):
    record_count: int
    subject_count: int
    unique_usubjids: List[str]


class RiskScoreResponse(BaseModel):
    subject_id: str
    risk_score: int
    risk_category: str


# ---------------------------------------------------------------------------
# Severity scoring map
# ---------------------------------------------------------------------------

SEVERITY_WEIGHTS: dict[str, int] = {
    "MILD":     1,
    "MODERATE": 3,
    "SEVERE":   5,
}


def _risk_category(score: int) -> str:
    if score < 5:
        return "Low"
    if score < 15:
        return "Medium"
    return "High"


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/", summary="Health check")
def root():
    """Returns a welcome message confirming the API is running."""
    return {"message": "Clinical Trial Data API is running"}


@app.post(
    "/ae-query",
    response_model=AEQueryResponse,
    summary="Dynamic AE cohort filter",
)
def ae_query(request: AEQueryRequest):
    """
    Filter the ADAE dataset by optional severity and/or treatment arm.

    - **severity**: list of AESEV values (MILD / MODERATE / SEVERE). Omit to include all.
    - **treatment_arm**: ACTARM value. Omit to include all arms.

    Returns the matching record count, unique subject count, and list of USUBJIDs.
    """
    filtered = df.copy()

    # Apply AESEV filter if provided
    if request.severity:
        sev_upper = [s.upper().strip() for s in request.severity]
        filtered = filtered[filtered["AESEV"].isin(sev_upper)]

    # Apply ACTARM filter if provided
    if request.treatment_arm:
        arm_upper = request.treatment_arm.upper().strip()
        filtered = filtered[filtered["ACTARM"] == arm_upper]

    unique_subjects = sorted(filtered["USUBJID"].unique().tolist())

    return AEQueryResponse(
        record_count=len(filtered),
        subject_count=len(unique_subjects),
        unique_usubjids=unique_subjects,
    )


@app.get(
    "/subject-risk/{subject_id}",
    response_model=RiskScoreResponse,
    summary="Patient safety risk score",
)
def subject_risk(subject_id: str):
    """
    Calculate a weighted Safety Risk Score for a specific subject.

    **Scoring weights (per AE record)**:
    - MILD     → 1 point
    - MODERATE → 3 points
    - SEVERE   → 5 points

    **Risk categories**:
    - Low    : score < 5
    - Medium : 5 ≤ score < 15
    - High   : score ≥ 15

    Returns a 404 if the subject ID is not found in the dataset.
    """
    subject_aes = df[df["USUBJID"] == subject_id.strip()]

    if subject_aes.empty:
        raise HTTPException(
            status_code=404,
            detail=f"Subject '{subject_id}' does not exist.",
        )

    risk_score = int(
        subject_aes["AESEV"]
        .map(SEVERITY_WEIGHTS)
        .fillna(0)          # unknown / missing severity values score 0
        .sum()
    )

    return RiskScoreResponse(
        subject_id=subject_id,
        risk_score=risk_score,
        risk_category=_risk_category(risk_score),
    )