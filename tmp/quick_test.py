import requests
import json
import uuid
from datetime import datetime, timedelta
import os

URL = "http://127.0.0.1:8000/sessions"
IMAGE_PATH = r"C:\Users\bowjo\.gemini\antigravity\brain\286574b2-909e-4052-87e6-29ba0d30717a\test_face_sample_1772906520398.png"

def build_session(rating_value):
    started = datetime.now()
    modules = ["mood", "anxiety", "social", "sleep", "energy", "cognitive"]
    
    module_scores = {}
    for mod in modules:
        module_scores[mod] = {
            "module": mod,
            "total_score": int(rating_value * 10),
            "question_count": 10,
            "average_score": float(rating_value),
            "max_possible": 50,
            "severity": "test"
        }
        
    session_data = {
        "session_id": str(uuid.uuid4()),
        "started_at": started.isoformat(),
        "completed_at": (started + timedelta(minutes=5)).isoformat(),
        "app_version": "1.0.0",
        "total_questions_answered": 0,
        "is_high_risk": False,
        "module_scores": module_scores,
        "responses": [],
        "user_text": "Falling back to module scores test",
        "safety_flags": []
    }
    return json.dumps(session_data)

if not os.path.exists(IMAGE_PATH):
    print(f"Error: Image not found at {IMAGE_PATH}")
    exit(1)

session_json = build_session(1.0)

with open(IMAGE_PATH, "rb") as f:
    face_content = f.read()

# Dummy wav content (header only or just plain bytes, librosa might complain but let's try)
voice_content = b"WAVE" + b"\x00" * 1000

files = {
    "face_image": ("face.png", face_content, "image/png"),
    "voice_audio": ("voice.wav", voice_content, "audio/wav")
}

try:
    r = requests.post(URL, data={"session": session_json}, files=files, timeout=20)
    print(f"Status: {r.status_code}")
    if r.status_code == 201:
        res = r.json()
        print(f"Result: {res.get('risk_level')} (Score: {res.get('risk_score')})")
        print(f"Response Body: {json.dumps(res, indent=2)}")
    else:
        print(f"Error Body: {r.text[:500]}")
except Exception as e:
    print(f"Error: {e}")
