import requests
import json
import uuid
from datetime import datetime, timedelta

URL = "http://127.0.0.1:8000/sessions"

def build_session(rating_value):
    started = datetime.now()
    
    modules = ["mood", "anxiety", "social", "sleep", "energy", "cognitive"]
    module_scores = {}
    for mod in modules:
        module_scores[mod] = {
            "module": mod,
            "total_score": rating_value * 10,
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
        "user_text": "I feel quite stressed and tired lately.",
        "safety_flags": [],
        "module_scores": module_scores,
        "responses": []
    }
    return json.dumps(session_data)

def run_test(name, rating):
    print(f"Running Test: {name} (Rating={rating})")
    session_json = build_session(rating)
    
    face_content = b"fake face image content"
    voice_content = b"fake voice audio content"
    
    files = {
        "face_image": ("face.jpg", face_content, "image/jpeg"),
        "voice_audio": ("voice.wav", voice_content, "audio/wav")
    }
    
    data = {
        "session": session_json
    }
    
    try:
        r = requests.post(URL, data=data, files=files, timeout=10)
        print(f"Status: {r.status_code}")
        if r.status_code == 201 or r.status_code == 200:
            print(f"Response: {json.dumps(r.json(), indent=2)}")
        else:
            print(f"Response Body: {r.text}")
    except Exception as e:
        print(f"Error: {e}")
    print("-" * 50)

if __name__ == "__main__":
    run_test("Low Risk Test", rating=0.2)
    run_test("Moderate Risk Test", rating=0.5)
    run_test("High Risk Test", rating=0.8)
