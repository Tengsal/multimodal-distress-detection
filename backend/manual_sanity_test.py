import requests
import uuid
from datetime import datetime, timedelta

URL = "http://127.0.0.1:8080/sessions"


def build_session(rating_value, latency_seconds):
    started = datetime.utcnow()
    current = started

    responses = []

    for i in range(20):
        current += timedelta(seconds=latency_seconds)

        responses.append({
            "question_id": f"q_{i}",
            "module": "mood",
            "question_text": "Manual sanity test",
            "rating": rating_value,
            "answered_at": current.isoformat()
        })

    return {
        "session_id": str(uuid.uuid4()),
        "started_at": started.isoformat(),
        "completed_at": current.isoformat(),
        "app_version": "1.0.0",
        "total_questions_answered": 20,
        "is_high_risk": False,
        "safety_flags": [],
        "module_scores": {
            "mood": {
                "module": "mood",
                "total_score": rating_value * 20,
                "question_count": 20,
                "average_score": rating_value,
                "max_possible": 100,
                "severity": "manual_test"
            }
        },
        "responses": responses
    }


def test_case(name, rating, latency):
    session = build_session(rating, latency)
    r = requests.post(URL, json=session)
    print(f"{name} → {r.status_code}")
    print(r.text)
    print("-" * 50)


if __name__ == "__main__":
    print("Running sanity tests...\n")

    # Case 1: All 1’s, very fast
    test_case("ALL 1s + FAST", rating=1, latency=0.4)

    # Case 2: All 3’s, medium
    test_case("ALL 3s + MEDIUM", rating=3, latency=1.5)

    # Case 3: All 5’s, slow
    test_case("ALL 5s + SLOW", rating=5, latency=3.5)