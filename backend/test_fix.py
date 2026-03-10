import requests
import json
import uuid
from datetime import datetime

URL = "http://127.0.0.1:8080/sessions"

def test_session_submission():
    session_id = str(uuid.uuid4())
    started_at = datetime.utcnow().isoformat()
    
    session_data = {
        "session_id": session_id,
        "started_at": started_at,
        "completed_at": datetime.utcnow().isoformat(),
        "app_version": "1.0.0",
        "total_questions_answered": 1,
        "is_high_risk": False,
        "user_text": "I am feeling a bit stressed but generally okay.",
        "safety_flags": [],
        "module_scores": {
            "mood": {
                "module": "mood",
                "total_score": 2,
                "question_count": 1,
                "average_score": 2.0,
                "max_possible": 5,
                "severity": "none"
            }
        },
        "responses": [
            {
                "question_id": "mood_01",
                "module": "mood",
                "question_text": "How is your mood?",
                "rating": 2,
                "answered_at": datetime.utcnow().isoformat()
            }
        ]
    }

    # Simulate multipart form data
    files = {
        "face_image": ("face.webm", b"fake video content", "video/webm"),
        "voice_audio": ("voice.wav", b"fake audio content", "audio/wav")
    }
    data = {
        "session": json.dumps(session_data)
    }

    print(f"Submitting session {session_id} to {URL}...")
    try:
        response = requests.post(URL, data=data, files=files)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
        
        if response.status_code == 201:
            print("SUCCESS: Session submitted successfully.")
        else:
            print(f"FAILED: Unexpected status code {response.status_code}")
            
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    test_session_submission()
