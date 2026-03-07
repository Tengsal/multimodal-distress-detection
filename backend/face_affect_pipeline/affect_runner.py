import sys
from pathlib import Path
import numpy as np
import cv2
import librosa

# ---------------------------------------------------------
# Fix import path to face_module
# ---------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parents[1]
FACE_MODULE_DIR = BASE_DIR / "face_module"

if str(FACE_MODULE_DIR) not in sys.path:
    sys.path.append(str(FACE_MODULE_DIR))

# ---------------------------------------------------------
# Import face modules
# ---------------------------------------------------------

from detection.face_detector import FaceDetector
from alignment.face_landmarks import FaceLandmarks
from emotion_model.emotion_classifier import EmotionClassifier

from features.valence_arousal import ValenceArousalCalculator
from features.distress_score import DistressScoreCalculator
from features.facial_behavior import FacialBehaviorExtractor
from features.feature_fusion import FeatureFusion

# ---------------------------------------------------------
# Import voice modules
# ---------------------------------------------------------

from voice_module.features.mfcc_extractor import MFCCExtractor
from voice_module.features.pitch_extractor import PitchExtractor
from voice_module.features.jitter_shimmer import JitterShimmerExtractor
from voice_module.voice_emotion_model import VoiceEmotionModel


# =========================================================
# Multimodal Affect Pipeline
# =========================================================

def run_affect_pipeline(face_path: str, voice_path: str):

    detector = FaceDetector()
    landmarks_detector = FaceLandmarks()
    classifier = EmotionClassifier()

    va_calculator = ValenceArousalCalculator()
    distress_calculator = DistressScoreCalculator()

    behavior_extractor = FacialBehaviorExtractor()
    fusion = FeatureFusion()

    mfcc_extractor = MFCCExtractor()
    pitch_extractor = PitchExtractor()
    js_extractor = JitterShimmerExtractor()
    voice_model = VoiceEmotionModel()

    # -----------------------------------------------------
    # Default outputs (in case of failure)
    # -----------------------------------------------------
    v, a, d = 0.5, 0.0, 0.0  # Valence, Arousal, Distress
    behavior_features = {"blink_rate": 0, "mouth_open": 0, "head_movement": 0}
    voice_emotion = {"valence": 0.5, "arousal": 0.0, "distress": 0.0}
    voice_features = {"pitch": 0, "jitter": 0, "shimmer": 0, "energy": 0}

    # =====================================================
    # PATH VALIDATION
    # =====================================================

    p_face = Path(face_path)
    p_voice = Path(voice_path)

    # =====================================================
    # FACE PROCESSING
    # =====================================================

    if p_face.exists():
        try:
            frame = cv2.imread(str(p_face))
            if frame is None:
                # Small retry delay for potential FS sync
                import time
                time.sleep(0.1)
                frame = cv2.imread(str(p_face))
            
            if frame is not None:
                faces = detector.detect_faces(frame)
                if len(faces) > 0:
                    x, y, w, h, face = faces[0]
                    emotion_probs = classifier.predict_emotion(face)
                    if emotion_probs:
                        v, a = va_calculator.compute(emotion_probs)
                        d = distress_calculator.compute(v, a)
                    
                    landmarks = landmarks_detector.extract_landmarks(face)
                    if landmarks:
                        behavior_features = behavior_extractor.compute_features(landmarks)
                else:
                    print("No face detected in image")
            else:
                print(f"CV2 failed to decode image at: {p_face.resolve()}")
        except Exception as e:
            print(f"Face processing error: {e}")
    else:
        print(f"Face file MISSING at: {p_face.resolve()}")

    # =====================================================
    # VOICE PROCESSING
    # =====================================================

    if p_voice.exists():
        try:
            audio_signal, sr = librosa.load(str(p_voice), sr=16000)
            if audio_signal is not None and len(audio_signal) > 0:
                energy = np.sum(audio_signal ** 2)
                mfcc = mfcc_extractor.extract(audio_signal)
                pitch = pitch_extractor.extract(audio_signal)
                
                # Basic sanity signal for jitter/shimmer
                pitch_series = [pitch] * 20
                amp_series = np.abs(audio_signal[:20]) if len(audio_signal) >= 20 else np.pad(np.abs(audio_signal), (0, 20-len(audio_signal)))

                jitter, shimmer = js_extractor.compute(pitch_series, amp_series)

                voice_features = {
                    "pitch": float(pitch),
                    "jitter": float(jitter),
                    "shimmer": float(shimmer),
                    "energy": float(energy)
                }

                voice_emotion = voice_model.compute(
                    mfcc, pitch, jitter, shimmer, energy
                )
        except Exception as e:
            print(f"Voice processing error: {e}")
    else:
        print(f"Voice file MISSING at: {p_voice.resolve()}")

    # =====================================================
    # FEATURE FUSION
    # =====================================================

    try:
        feature_vector = fusion.fuse(
            v,
            a,
            d,
            behavior_features,
            voice_emotion,
            voice_features
        )
        return feature_vector.tolist()
    except Exception as e:
        print(f"Fusion error: {e}")
        return np.zeros(12).tolist()
