# backend/generate_synthetic_sessions_v2.py

import requests
import uuid
import random
import json
import os
import time
from datetime import datetime, timedelta

URL = "http://127.0.0.1:8000/sessions"
BASELINE_PATH = "data/baseline.json"

MODULES = ["sleep", "mood", "anxiety", "social", "energy", "cognitive"]

# 40% healthy | 30% mild | 20% moderate | 10% high risk
SEVERITY_WEIGHTS = [0.40, 0.30, 0.20, 0.10]

SEVERITY_PROFILES = {
    0: {"rating_range": (1, 2), "latency_mean": 0.9, "latency_std": 0.2},
    1: {"rating_range": (2, 3), "latency_mean": 1.6, "latency_std": 0.5},
    2: {"rating_range": (3, 4), "latency_mean": 2.5, "latency_std": 0.9},
    3: {"rating_range": (4, 5), "latency_mean": 3.0, "latency_std": 1.8},
}


def generate_session(severity_level: int) -> dict:
    profile = SEVERITY_PROFILES[severity_level]
    r_min, r_max = profile["rating_range"]

    started = datetime.utcnow()
    current_time = started
    responses = []

    # Guarantee balanced module distribution (3-4 per module)
    questions_per_module = 20 // len(MODULES)
    remainder = 20 % len(MODULES)

    question_id = 0

    for module in MODULES:
        count = questions_per_module + (1 if remainder > 0 else 0)
        if remainder > 0:
            remainder -= 1

        for _ in range(count):
            rating = random.randint(r_min, r_max)

            latency = max(
                0.2,
                random.gauss(profile["latency_mean"], profile["latency_std"])
            )

            current_time += timedelta(seconds=latency)

            responses.append({
                "question_id": f"q_{question_id}",
                "module": module,
                "question_text": "Synthetic question",
                "rating": rating,
                "answered_at": current_time.isoformat()
            })

            question_id += 1

    module_scores = {}

    for mod in MODULES:
        mod_responses = [r for r in responses if r["module"] == mod]
        total = sum(r["rating"] for r in mod_responses)
        count = len(mod_responses)

        module_scores[mod] = {
            "module": mod,
            "total_score": total,
            "question_count": count,
            "average_score": total / count,
            "max_possible": count * 5,
            "severity": ["healthy", "mild", "moderate", "high_risk"][severity_level]
        }

    return {
        "session_id": str(uuid.uuid4()),
        "started_at": started.isoformat(),
        "completed_at": current_time.isoformat(),
        "app_version": "1.0.0",
        "total_questions_answered": 20,
        "is_high_risk": severity_level == 3,
        "safety_flags": [],
        "module_scores": module_scores,
        "responses": responses
    }


def wipe_baseline():
    os.makedirs("data", exist_ok=True)
    with open(BASELINE_PATH, "w") as f:
        json.dump({"risk_scores": [], "latencies": []}, f)
    print("Baseline wiped.")


def main():
    print("=" * 60)
    print("Synthetic Population Generator v2 (Balanced & Realistic)")
    print("40% healthy | 30% mild | 20% moderate | 10% high risk")
    print("=" * 60)
    print()

    wipe_baseline()
    print()

    severities = random.choices([0, 1, 2, 3], weights=SEVERITY_WEIGHTS, k=200)

    counts = {0: 0, 1: 0, 2: 0, 3: 0}
    success = 0
    fail = 0

    for i, severity in enumerate(severities):
        session = generate_session(severity)
        label = ["healthy ", "mild    ", "moderate", "HIGH    "][severity]

        try:
            r = requests.post(URL, json=session, timeout=30)

            if r.status_code == 201:
                counts[severity] += 1
                success += 1
                print(f"Session {i+1:>3}/200 [{label}] -> 201 OK")
            else:
                fail += 1
                print(f"Session {i+1:>3}/200 [{label}] -> {r.status_code} FAIL")

        except Exception as e:
            fail += 1
            print(f"Session {i+1:>3}/200 [{label}] -> ERROR: {e}")
            time.sleep(1)

    print()
    print("=" * 60)
    print(f"RESULT: {success} succeeded, {fail} failed")
    print("Population breakdown:")
    print(f"Healthy:   {counts[0]}")
    print(f"Mild:      {counts[1]}")
    print(f"Moderate:  {counts[2]}")
    print(f"High Risk: {counts[3]}")
    print("=" * 60)
    print("Check backend/data/baseline.json")
    print()


if __name__ == "__main__":
    main()