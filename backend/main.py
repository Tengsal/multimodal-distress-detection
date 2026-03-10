from __future__ import annotations

import sys
import csv
import json
from pathlib import Path
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, status, UploadFile, File, Form, Depends, HTTPException, BackgroundTasks
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

# RAG-CBT Module
from rag_cbt.rag_service import RagService
from rag_cbt.therapy_graph import TherapyGraph

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

# Initialize RAG Services
rag_service = RagService()
therapy_graph = TherapyGraph()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

from fastapi.responses import JSONResponse
import traceback
from fastapi.exceptions import RequestValidationError

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    print("VALIDATION ERROR:", exc.errors())
    return JSONResponse(
        status_code=422,
        content={"status": "error", "message": "Validation Error", "details": exc.errors()}
    )

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    trace = traceback.format_exc()
    print("GLOBAL ERROR:", trace)
    return JSONResponse(
        status_code=500,
        content={"status": "error", "message": str(exc), "trace": trace}
    )

# ------------------------------------------------------------
# Storage Helpers
# ------------------------------------------------------------


def _append_json(data: dict):

    data["received_at"] = datetime.utcnow().isoformat()

    with open(SESSIONS_JSON, "a", encoding="utf-8") as f:
        f.write(json.dumps(data) + "\n")

def _update_session_rag(session_id: str, therapy_plan: dict, graph_path: str):
    """
    Updates the session record in the JSON file with the RAG results.
    """
    if not SESSIONS_JSON.exists():
        return
    
    updated_lines = []
    with open(SESSIONS_JSON, "r", encoding="utf-8") as f:
        for line in f:
            if not line.strip(): continue
            data = json.loads(line)
            if data.get("session_id") == session_id:
                data["therapy_plan"] = therapy_plan
                data["graph_path"] = graph_path
            updated_lines.append(json.dumps(data))
            
    with open(SESSIONS_JSON, "w", encoding="utf-8") as f:
        for line in updated_lines:
            f.write(line + "\n")


async def run_rag_background(session_id: str, risk: float, risk_level: str, quality_flags: List[str]):
    """
    Intensive clinical analysis run in background.
    """
    try:
        rag_state = {
            "emotion": risk_level.lower(),
            "risk_score": risk,
            "signals": quality_flags
        }
        print(f"BKG RAG: Starting analysis for {session_id}")
        therapy_plan = await run_in_threadpool(rag_service.generate_therapy_plan, rag_state)
        graph_path = await run_in_threadpool(therapy_graph.generate_roadmap, session_id, therapy_plan)
        
        # Update JSON record
        _update_session_rag(session_id, therapy_plan, graph_path)
        print(f"BKG RAG: Completed analysis for {session_id}")
    except Exception as e:
        print(f"BKG RAG ERROR: {e}")


def _append_csv(session: SessionIn, risk_score: float, risk_level: str):

    # Calculate total questions from modules if total_questions_answered is 0
    total_q = session.total_questions_answered
    if total_q == 0 and session.module_scores:
        total_q = sum(m.question_count for m in session.module_scores.values())

    row: Dict[str, Any] = {
        "session_id": session.session_id,
        "started_at": session.started_at,
        "completed_at": session.completed_at or "",
        "total_questions": total_q,
        "risk_score": f"{risk_score:.4f}",
        "risk_level": risk_level,
        "is_high_risk": 1 if risk_level == "HIGH" else 0,
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
    background_tasks: BackgroundTasks,
    session: str = Form(...),
    face_image: UploadFile = File(...),
    voice_audio: UploadFile = File(...)
) -> Dict[str, Any]:

    # ------------------------------------------------------------
    # Parse JSON session
    # ------------------------------------------------------------

    try:
        session_data = json.loads(session)
        # Handle case where flutter multipart request double-escapes the JSON string
        if isinstance(session_data, str):
            session_data = json.loads(session_data)
    except json.JSONDecodeError as e:
        print("JSON Decode Error string:", repr(session))
        return {
            "status": "error",
            "message": f"Invalid JSON payload: {str(e)}"
        }

    print("DEBUG: Raw Session Data:", json.dumps(session_data, indent=2))
    session_obj = SessionIn(**session_data)

    print("Session received:", session_obj.session_id)

    # --------------------------------------------
    # Save uploaded media
    # --------------------------------------------

    # Use extensions from uploaded files
    face_ext = face_image.filename.split('.')[-1] if face_image.filename and '.' in face_image.filename else "jpg"
    voice_ext = voice_audio.filename.split('.')[-1] if voice_audio.filename and '.' in voice_audio.filename else "wav"

    face_path = UPLOAD_DIR / f"{session_obj.session_id}_face.{face_ext}"
    voice_path = UPLOAD_DIR / f"{session_obj.session_id}_voice.{voice_ext}"

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
    # Explicit questionnaire features (All 6 modules)
    # --------------------------------------------

    module_averages = {}
    for mod in ["mood", "anxiety", "social", "sleep", "energy", "cognitive"]:
        score_obj = session_obj.module_scores.get(mod)
        module_averages[mod] = score_obj.average_score if score_obj else 0.0

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
        print(f"PIPELINE: Starting Affect for {session_obj.session_id}...")
        affect_features = run_affect_pipeline(
            str(face_path),
            str(voice_path)
        )
        print(f"PIPELINE: Affect completed for {session_obj.session_id}")

        if affect_features is None:
            affect_features = []

        print("Affect features:", affect_features)

    except Exception as e:
        print(f"PIPELINE: Affect error: {e}")
        affect_features = []

    # --------------------------------------------
    # Calculate Results
    # --------------------------------------------

    try:
        print(f"PIPELINE: Starting Mental State Engine for {session_obj.session_id}...")
        engine_output = run_pipeline(
            module_averages,
            free_text,
            latencies,
            affect_features
        )
        print(f"PIPELINE: Mental State Engine completed for {session_obj.session_id}")
    except Exception as e:
        print(f"PIPELINE: Mental State Engine error: {e}")
        return {"status": "error", "message": f"Mental State Engine failed: {str(e)}"}

    print("Engine Output:", engine_output)

    risk = engine_output["risk_score"]
    risk_level = engine_output["risk_level"]

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
    # Sync High Risk Flag
    # --------------------------------------------
    is_high = (risk_level == "HIGH")
    # --------------------------------------------
    # Store results (Basic)
    # --------------------------------------------

    session_record = session_obj.model_dump()
    session_record["engine_output"] = engine_output
    session_record["risk_score"] = risk
    session_record["risk_level"] = risk_level
    session_record["risk_z_score"] = risk_z
    session_record["latency_z_score"] = latency_z
    session_record["quality_flags"] = quality_flags
    session_record["therapy_plan"] = None # Will be updated by background task
    session_record["graph_path"] = None

    _append_json(session_record)
    _append_csv(session_obj, risk, risk_level)

    # --------------------------------------------
    # Queue RAG-CBT (Background)
    # --------------------------------------------
    if background_tasks:
        background_tasks.add_task(
            run_rag_background, 
            session_obj.session_id, 
            risk, 
            risk_level, 
            quality_flags
        )

    # --------------------------------------------
    # API response (Instant)
    # --------------------------------------------

    return {
        "status": "ok",
        "session_id": session_obj.session_id,
        "risk_score": risk,
        "risk_level": risk_level,
        "consistency": engine_output["consistency"],
        "risk_z_score": risk_z,
        "latency_z_score": latency_z,
        "quality_flags": quality_flags
    }


class MentalStateIn(BaseModel):
    emotion: str
    risk_score: float
    signals: List[str] = Field(default_factory=list)
    session_id: Optional[str] = None





class ChatQuery(BaseModel):
    query: str
    session_id: Optional[str] = None


from starlette.concurrency import run_in_threadpool

@app.post("/chat")
async def chat(data: ChatQuery):
    """
    Interactive RAG-based chat. (Async to prevent blocking)
    """
    print(f"RAG Chat Request: {data.query}")
    try:
        response = await run_in_threadpool(rag_service.chat, data.query, data.session_id)
        return {"status": "ok", "response": response}
    except Exception as e:
        print(f"Chat error: {e}")
        return {"status": "error", "message": str(e)}


@app.get("/session-history")
async def get_session_history():
    """
    Returns time-series risk data for progress visualization.
    """
    history = []
    if SESSIONS_JSON.exists():
        with open(SESSIONS_JSON, "r", encoding="utf-8") as f:
            for line in f:
                try:
                    data = json.loads(line)
                    history.append({
                        "session_id": data.get("session_id"),
                        "timestamp": data.get("received_at") or data.get("started_at"),
                        "risk_score": data.get("risk_score") or data.get("engine_output", {}).get("risk_score", 0.0),
                        "risk_level": data.get("risk_level") or data.get("engine_output", {}).get("risk_level", "UNKNOWN")
                    })
                except:
                    continue
    
    # Sort by timestamp
    history.sort(key=lambda x: x["timestamp"] if x["timestamp"] else "")
    return {"status": "ok", "history": history}


@app.get("/health")
async def health():

    return {
        "status": "ok",
        "time": datetime.utcnow().isoformat(),
    }