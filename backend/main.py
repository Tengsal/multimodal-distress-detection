from __future__ import annotations

import sys
import csv
import json
from pathlib import Path
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, status, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator

# ------------------------------------------------------------
# Path setup
# ------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent
sys.path.append(str(BASE_DIR))

DATA_DIR = BASE_DIR / "data"
UPLOAD_DIR = BASE_DIR / "uploads"

DATA_DIR.mkdir(parents=True, exist_ok=True)
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

SESSIONS_JSON = DATA_DIR / "sessions.json"
SESSIONS_CSV = DATA_DIR / "sessions.csv"

print("Backend starting...")
print("Backend path:", BASE_DIR)

# ------------------------------------------------------------
# ML Engine
# ------------------------------------------------------------

from mental_state_engine.src.main import run_pipeline
from face_affect_pipeline.affect_runner import run_affect_pipeline

from baseline_model import (
    update_baseline,
    compute_z_score,
    load_baseline,
)

# ------------------------------------------------------------
# Pydantic Models
# ------------------------------------------------------------


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

    user_text: Optional[str] = None

    safety_flags: List[SafetyFlagIn] = Field(default_factory=list)
    module_scores: Dict[str, ModuleScoreIn] = Field(default_factory=dict)
    responses: List[ResponseIn] = Field(default_factory=list)

    @field_validator("session_id")
    @classmethod
    def validate_uuid(cls, v: str) -> str:
        import uuid
        uuid.UUID(v)
        return v


# ------------------------------------------------------------
# FastAPI App
# ------------------------------------------------------------

app = FastAPI(title="Multimodal Mental Health API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------------------------------------
# Storage Helpers
# ------------------------------------------------------------


def _append_json(data: dict):

    data["received_at"] = datetime.utcnow().isoformat()

    with open(SESSIONS_JSON, "a", encoding="utf-8") as f:
        f.write(json.dumps(data) + "\n")


def _append_csv(session: SessionIn):

    row: Dict[str, Any] = {
        "session_id": session.session_id,
        "started_at": session.started_at,
        "completed_at": session.completed_at or "",
        "total_questions": session.total_questions_answered,
        "is_high_risk": int(session.is_high_risk),
        "received_at": datetime.utcnow().isoformat(),
    }

    file_exists = SESSIONS_CSV.exists() and SESSIONS_CSV.stat().st_size > 0

    with open(SESSIONS_CSV, "a", newline="", encoding="utf-8") as f:

        writer = csv.DictWriter(f, fieldnames=row.keys())

        if not file_exists:
            writer.writeheader()

        writer.writerow(row)


# ------------------------------------------------------------
# Routes
# ------------------------------------------------------------


@app.post("/sessions", status_code=status.HTTP_201_CREATED)
async def create_session(
    session: str = Form(...),
    face_image: UploadFile = File(...),
    voice_audio: UploadFile = File(...),
) -> Dict[str, Any]:

    # --------------------------------------------
    # Parse JSON session
    # --------------------------------------------

    session_data = json.loads(session)
    session_obj = SessionIn(**session_data)

    print("Session received:", session_obj.session_id)

    # --------------------------------------------
    # Save uploaded media
    # --------------------------------------------

    face_path = UPLOAD_DIR / f"{session_obj.session_id}_face.jpg"
    voice_path = UPLOAD_DIR / f"{session_obj.session_id}_voice.wav"

    try:

        with open(face_path, "wb") as f:
            f.write(await face_image.read())

        with open(voice_path, "wb") as f:
            f.write(await voice_audio.read())

        print("Saved face:", face_path)
        print("Saved voice:", voice_path)

    except Exception as e:

        print("File saving error:", e)

        return {
            "status": "error",
            "message": "Failed to save uploaded files"
        }

    # --------------------------------------------
    # Explicit questionnaire features
    # --------------------------------------------

    explicit_vector = [
        session_obj.module_scores.get("mood").average_score
        if session_obj.module_scores.get("mood")
        else 0,

        session_obj.module_scores.get("sleep").average_score
        if session_obj.module_scores.get("sleep")
        else 0,

        session_obj.module_scores.get("anxiety").average_score
        if session_obj.module_scores.get("anxiety")
        else 0,
    ]

    # --------------------------------------------
    # Latency features
    # --------------------------------------------

    latencies = []
    avg_latency = 0

    if session_obj.responses:

        times = [datetime.fromisoformat(r.answered_at) for r in session_obj.responses]

        for i in range(1, len(times)):

            delta = (times[i] - times[i - 1]).total_seconds()
            latencies.append(delta)

        if latencies:
            avg_latency = sum(latencies) / len(latencies)

    # --------------------------------------------
    # Text input
    # --------------------------------------------

    free_text = (session_obj.user_text or "").strip()

    # --------------------------------------------
    # Affect pipeline (Face + Voice)
    # --------------------------------------------

    try:

        affect_features = run_affect_pipeline(
            str(face_path),
            str(voice_path)
        )

        if affect_features is None:
            affect_features = []

        print("Affect features:", affect_features)

    except Exception as e:

        print("Affect pipeline error:", e)
        affect_features = []

    # --------------------------------------------
    # ML risk pipeline
    # --------------------------------------------

    engine_output = run_pipeline(
        explicit=explicit_vector,
        text=free_text,
        latencies=latencies,
        affect=affect_features,
    )

    print("Engine Output:", engine_output)

    risk = engine_output["risk_score"]

    # --------------------------------------------
    # Statistical baseline normalization
    # --------------------------------------------

    baseline_data = load_baseline()

    risk_z = compute_z_score(risk, baseline_data["risk_scores"])
    latency_z = compute_z_score(avg_latency, baseline_data["latencies"])

    quality_flags = []

    if abs(risk_z) > 2:
        quality_flags.append("risk_outlier")

    if abs(latency_z) > 2:
        quality_flags.append("latency_outlier")

    update_baseline(risk, avg_latency)

    # --------------------------------------------
    # Store results
    # --------------------------------------------

    session_record = session_obj.model_dump()

    session_record["engine_output"] = engine_output
    session_record["risk_z_score"] = risk_z
    session_record["latency_z_score"] = latency_z
    session_record["quality_flags"] = quality_flags

    _append_json(session_record)
    _append_csv(session_obj)

    # --------------------------------------------
    # API response
    # --------------------------------------------

    return {
        "status": "ok",
        "session_id": session_obj.session_id,
        "risk_score": risk,
        "consistency": engine_output["consistency"],
        "risk_z_score": risk_z,
        "latency_z_score": latency_z,
        "quality_flags": quality_flags,
    }


@app.get("/health")
async def health():

    return {
        "status": "ok",
        "time": datetime.utcnow().isoformat(),
    }