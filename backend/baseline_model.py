import json
from pathlib import Path
from statistics import mean, pstdev

BASELINE_FILE = Path("data/baseline_stats.json")


def load_baseline():
    if not BASELINE_FILE.exists():
        return {
            "risk_scores": [],
            "latencies": []
        }
    with open(BASELINE_FILE, "r") as f:
        return json.load(f)


def save_baseline(data):
    with open(BASELINE_FILE, "w") as f:
        json.dump(data, f, indent=2)


def update_baseline(risk_score: float, avg_latency: float):
    data = load_baseline()

    data["risk_scores"].append(risk_score)
    data["latencies"].append(avg_latency)

    save_baseline(data)


def compute_stats(values):
    if len(values) < 2:
        return None, None
    return mean(values), pstdev(values)


def compute_z_score(value, values):
    m, s = compute_stats(values)
    if m is None or s == 0:
        return 0
    return (value - m) / s