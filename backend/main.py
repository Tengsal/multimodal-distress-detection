from __future__ import annotations

import csv
import json
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator

# ================================================================
# PATH CONFIGURATION (ABSOLUTE + DEBUG SAFE)
# ================================================================

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
SESSIONS_JSON = DATA_DIR / "sessions.json"
SESSIONS_CSV  = DATA_DIR / "sessions.csv"

DATA_DIR.mkdir(parents=True, exist_ok=True)

print("🔥 Backend starting...")
print("📂 BASE_DIR:", BASE_DIR)
print("📂 DATA_DIR:", DATA_DIR)
print("📄 JSON PATH:", SESSIONS_JSON)
print("📄 CSV PATH:", SESSIONS_CSV)

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
# STORAGE
# ================================================================

def _append_json(session: SessionIn) -> None:
    record = session.model_dump()
    record["received_at"] = datetime.utcnow().isoformat()

    print("📝 Writing JSON to:", SESSIONS_JSON)

    with open(SESSIONS_JSON, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def _append_csv(session: SessionIn) -> None:
    # ── 1. Metadata ───────────────────────────────────────────────
    row: Dict[str, Any] = {
        "session_id":    session.session_id,
        "started_at":    session.started_at,
        "completed_at":  session.completed_at or "",
        "app_version":   session.app_version,
        "total_questions": session.total_questions_answered,
        "is_high_risk":  int(session.is_high_risk),
        "received_at":   datetime.utcnow().isoformat(),
    }

    # ── 2. Module scores (6 modules × 3 columns each) ─────────────
    # Produces: sleep_total, sleep_avg, sleep_severity, mood_total, ...
    modules = ["sleep", "mood", "anxiety", "social", "energy", "cognitive"]
    for mod in modules:
        score = session.module_scores.get(mod)
        if score:
            row[f"{mod}_total"]    = score.total_score
            row[f"{mod}_avg"]      = round(score.average_score, 3)
            row[f"{mod}_severity"] = score.severity
        else:
            row[f"{mod}_total"]    = 0
            row[f"{mod}_avg"]      = 0.0
            row[f"{mod}_severity"] = "none"

    # ── 3. Safety flags (binary columns: 1 = fired, 0 = not) ──────
    known_flags = [
        "PASSIVE_SUICIDAL_IDEATION",
        "ACTIVE_SELF_HARM_IDEATION",
        "PERSISTENT_SUICIDAL_IDEATION",
        "SUICIDAL_PLAN",
        "NO_HELP_SOUGHT_IDEATION",
        "PERCEIVED_BURDENSOMENESS",
        "SEVERE_HOPELESSNESS",
        "FREQUENT_PANIC_ATTACKS",
        "SEVERE_SLEEP_IMPAIRMENT",
        "SUBSTANCE_SLEEP_DEPENDENCY",
        "DISORDERED_EATING_RISK",
        "PHYSICAL_HEALTH_NEGLECT",
    ]
    fired_codes = {f.code for f in session.safety_flags}
    for code in known_flags:
        row[f"flag_{code}"] = 1 if code in fired_codes else 0

    # ── 4. Write ───────────────────────────────────────────────────
    file_exists = SESSIONS_CSV.exists() and SESSIONS_CSV.stat().st_size > 0

    print("📝 Writing CSV to:", SESSIONS_CSV)
    print("   Columns:", len(row), "| Modules found:", list(session.module_scores.keys()))
    print("   Flags fired:", list(fired_codes) if fired_codes else "none")

    with open(SESSIONS_CSV, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(row.keys()))
        if not file_exists:
            writer.writeheader()
            print("   ✅ CSV header written (new file)")
        writer.writerow(row)
        print("   ✅ CSV row written")


def _load_all_sessions() -> List[Dict[str, Any]]:
    if not SESSIONS_JSON.exists():
        return []
    sessions = []
    with open(SESSIONS_JSON, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                sessions.append(json.loads(line))
    return sessions


# ================================================================
# ROUTES
# ================================================================

@app.post("/sessions", status_code=status.HTTP_201_CREATED)
async def create_session(session: SessionIn) -> Dict[str, Any]:

    print("✅ Session received:", session.session_id)
    print("   Questions answered:", session.total_questions_answered)
    print("   High risk:", session.is_high_risk)
    print("   Module scores keys:", list(session.module_scores.keys()))
    print("   Safety flags:", [f.code for f in session.safety_flags])

    _append_json(session)
    _append_csv(session)

    if session.is_high_risk:
        _handle_high_risk(session)

    return {
        "status": "ok",
        "session_id": session.session_id,
        "received_at": datetime.utcnow().isoformat(),
        "total_questions": session.total_questions_answered,
        "is_high_risk": session.is_high_risk,
        "flags_raised": len(session.safety_flags),
        "message": (
            "⚠️  HIGH RISK SESSION — review immediately."
            if session.is_high_risk
            else "Session stored successfully."
        ),
    }


@app.get("/sessions")
async def list_sessions() -> List[Dict[str, Any]]:
    sessions = _load_all_sessions()
    return [
        {
            "session_id":      s.get("session_id"),
            "started_at":      s.get("started_at"),
            "completed_at":    s.get("completed_at"),
            "total_questions": s.get("total_questions_answered"),
            "is_high_risk":    s.get("is_high_risk"),
            "flags_raised":    len(s.get("safety_flags", [])),
        }
        for s in sessions
    ]


@app.get("/sessions/{session_id}")
async def get_session(session_id: str) -> Dict[str, Any]:
    for s in _load_all_sessions():
        if s.get("session_id") == session_id:
            return s
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=f"Session '{session_id}' not found.",
    )


@app.get("/health")
async def health() -> Dict[str, str]:
    return {"status": "ok", "time": datetime.utcnow().isoformat()}


# ================================================================
# HIGH-RISK HANDLER
# ================================================================

def _handle_high_risk(session: SessionIn) -> None:
    print(
        f"\n{'='*60}\n"
        f"⚠️  HIGH RISK SESSION DETECTED\n"
        f"   Session ID : {session.session_id}\n"
        f"   Started at : {session.started_at}\n"
        f"   Flags      : {[f.code for f in session.safety_flags if f.severity == 'HIGH']}\n"
        f"{'='*60}\n"
    )

    hr_path = DATA_DIR / "high_risk_sessions.json"
    record = session.model_dump()
    record["received_at"] = datetime.utcnow().isoformat()
    with open(hr_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")