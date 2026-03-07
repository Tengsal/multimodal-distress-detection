import requests
import json
import uuid
from datetime import datetime, timedelta

URL = "http://127.0.0.1:8000/sessions"

def build_session(rating_value):
    started = datetime.now()
    modules = ["mood", "anxiety", "social", "sleep", "energy", "cognitive"]
    
    # Fill ALL required fields for ModuleScoreIn
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
        "total_questions_answered": 60,
        "is_high_risk": False,
        "module_scores": module_scores,
        "responses": [],
        "user_text": "Test session text",
        "safety_flags": []
    }
    return json.dumps(session_data)

session_json = build_session(1.0)
files = {
    "face_image": ("face.jpg", b"fake", "image/jpeg"),
    "voice_audio": ("voice.wav", b"fake", "audio/wav")
}
try:
    r = requests.post(URL, data={"session": session_json}, files=files, timeout=10)
    print(f"Status: {r.status_code}")
    if r.status_code == 201:
        res = r.json()
        print(f"Result: {res.get('risk_level')} (Score: {res.get('risk_score')})")
    else:
        print(f"Error Body: {r.text[:500]}")
except Exception as e:
    print(f"Error: {e}")
