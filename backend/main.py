from __future__ import annotations

import sys
from pathlib import Path

# --------------------------------------------------
# FIX PYTHON PATH (Windows + Uvicorn Safe)
# --------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent
sys.path.append(str(BASE_DIR))

import csv
import json
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator

# 🔥 Import ML Engine
from mental_state_engine.src.main import run_pipeline

# 🔥 Import Statistical Baseline Layer
from baseline_model import (
    update_baseline,
    compute_z_score,
    load_baseline,
)

# ================================================================
# DATA PATHS
# ================================================================

DATA_DIR = BASE_DIR / "data"
SESSIONS_JSON = DATA_DIR / "sessions.json"
SESSIONS_CSV = DATA_DIR / "sessions.csv"

DATA_DIR.mkdir(parents=True, exist_ok=True)

print("🔥 Backend starting...")
print("📂 Backend Path:", BASE_DIR)


# ================================================================
# MODELS
# ================================================================

class SafetyFlagIn(BaseModel):
    code: str
    label: str
    triggered_by: str
    rating: int
    severity: str


class ModuleScoreIn(BaseModel):
    module: str
    total_score: int
    question_count: int
    average_score: float
    max_possible: int
    severity: str


class ResponseIn(BaseModel):
    question_id: str
    module: str
    question_text: str
    rating: int = Field(..., ge=1, le=5)
    answered_at: str


class SessionIn(BaseModel):
    session_id: str
    started_at: str
    completed_at: Optional[str] = None
    app_version: str = "1.0.0"
    total_questions_answered: int
    is_high_risk: bool
    safety_flags: List[SafetyFlagIn] = []
    module_scores: Dict[str, ModuleScoreIn] = {}
    responses: List[ResponseIn] = []

    @field_validator("session_id")
    @classmethod
    def validate_uuid(cls, v: str) -> str:
        uuid.UUID(v)
        return v


# ================================================================
# FASTAPI APP
# ================================================================

app = FastAPI(title="Mental Health API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ================================================================
# STORAGE HELPERS
# ================================================================

def _append_json(data: dict) -> None:
    data["received_at"] = datetime.utcnow().isoformat()
    with open(SESSIONS_JSON, "a", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=False) + "\n")


def _append_csv(session: SessionIn) -> None:
    row: Dict[str, Any] = {
        "session_id": session.session_id,
        "started_at": session.started_at,
        "completed_at": session.completed_at or "",
        "app_version": session.app_version,
        "total_questions": session.total_questions_answered,
        "is_high_risk": int(session.is_high_risk),
        "received_at": datetime.utcnow().isoformat(),
    }

    modules = ["sleep", "mood", "anxiety", "social", "energy", "cognitive"]

    for mod in modules:
        score = session.module_scores.get(mod)
        if score:
            row[f"{mod}_total"] = score.total_score
            row[f"{mod}_avg"] = round(score.average_score, 3)
            row[f"{mod}_severity"] = score.severity
        else:
            row[f"{mod}_total"] = 0
            row[f"{mod}_avg"] = 0.0
            row[f"{mod}_severity"] = "none"

    file_exists = SESSIONS_CSV.exists() and SESSIONS_CSV.stat().st_size > 0

    with open(SESSIONS_CSV, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(row.keys()))
        if not file_exists:
            writer.writeheader()
        writer.writerow(row)


# ================================================================
# ROUTES
# ================================================================

@app.post("/sessions", status_code=status.HTTP_201_CREATED)
async def create_session(session: SessionIn) -> Dict[str, Any]:

    print("✅ Session received:", session.session_id)

    # --------------------------------------------------
    # Build Explicit Vector
    # --------------------------------------------------
    explicit_vector = [
        session.module_scores.get("mood").average_score if session.module_scores.get("mood") else 0,
        session.module_scores.get("sleep").average_score if session.module_scores.get("sleep") else 0,
        session.module_scores.get("anxiety").average_score if session.module_scores.get("anxiety") else 0,
    ]

    # --------------------------------------------------
    # Compute Latencies Between Questions
    # --------------------------------------------------
    latencies = []
    avg_latency = 0

    if session.responses:
        times = [datetime.fromisoformat(r.answered_at) for r in session.responses]

        for i in range(1, len(times)):
            delta = (times[i] - times[i - 1]).total_seconds()
            latencies.append(delta)

        if latencies:
            avg_latency = sum(latencies) / len(latencies)

    # --------------------------------------------------
    # Placeholder Free Text (Phase 1)
    # --------------------------------------------------
    free_text = "User reports mild mood and sleep disturbance."

    # --------------------------------------------------
    # Run ML Engine
    # --------------------------------------------------
    engine_output = run_pipeline(
        explicit=explicit_vector,
        text=free_text,
        latencies=latencies,
    )

    print("🧠 Engine Output:", engine_output)

    # --------------------------------------------------
    # Statistical Baseline Layer
    # --------------------------------------------------
    risk = engine_output["risk_score"]

    baseline_data = load_baseline()

    risk_z = compute_z_score(risk, baseline_data["risk_scores"])
    latency_z = compute_z_score(avg_latency, baseline_data["latencies"])

    quality_flags = []

    if abs(risk_z) > 2:
        quality_flags.append("risk_outlier")

    if abs(latency_z) > 2:
        quality_flags.append("latency_outlier")

    # Update baseline AFTER computing z-scores
    update_baseline(risk, avg_latency)

    # --------------------------------------------------
    # Store Everything
    # --------------------------------------------------
    session_record = session.model_dump()
    session_record["engine_output"] = engine_output
    session_record["risk_z_score"] = risk_z
    session_record["latency_z_score"] = latency_z
    session_record["quality_flags"] = quality_flags

    _append_json(session_record)
    _append_csv(session)

    return {
        "status": "ok",
        "session_id": session.session_id,
        "risk_score": risk,
        "consistency": engine_output["consistency"],
        "risk_z_score": risk_z,
        "latency_z_score": latency_z,
        "quality_flags": quality_flags,
    }


@app.get("/health")
async def health():
    return {"status": "ok", "time": datetime.utcnow().isoformat()}