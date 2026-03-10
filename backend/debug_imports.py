#!/usr/bin/env python3
"""
Debug script to test imports one by one
"""
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
sys.path.append(str(BASE_DIR))

print("Testing imports step by step...")

try:
    print("1. Importing FastAPI...")
    from fastapi import FastAPI, status, UploadFile, File, Form
    print("   ✓ FastAPI OK")
except Exception as e:
    print(f"   ✗ FastAPI failed: {e}")
    sys.exit(1)

try:
    print("2. Importing CORS...")
    from fastapi.middleware.cors import CORSMiddleware
    print("   ✓ CORS OK")
except Exception as e:
    print(f"   ✗ CORS failed: {e}")
    sys.exit(1)

try:
    print("3. Importing Pydantic...")
    from pydantic import BaseModel, Field, field_validator
    print("   ✓ Pydantic OK")
except Exception as e:
    print(f"   ✗ Pydantic failed: {e}")
    sys.exit(1)

try:
    print("4. Importing baseline_model...")
    from baseline_model import update_baseline, compute_z_score, load_baseline
    print("   ✓ baseline_model OK")
except Exception as e:
    print(f"   ✗ baseline_model failed: {e}")
    sys.exit(1)

try:
    print("5. Importing mental_state_engine...")
    from mental_state_engine.src.main import run_pipeline
    print("   ✓ mental_state_engine OK")
except Exception as e:
    print(f"   ✗ mental_state_engine failed: {e}")
    sys.exit(1)

try:
    print("6. Importing affect_pipeline...")
    from face_affect_pipeline.affect_runner import run_affect_pipeline
    print("   ✓ affect_pipeline OK")
except Exception as e:
    print(f"   ✗ affect_pipeline failed: {e}")
    sys.exit(1)

print("\nAll imports successful!")
