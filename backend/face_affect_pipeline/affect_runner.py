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

    try:

        # =====================================================
        # FACE PROCESSING
        # =====================================================

        frame = cv2.imread(face_path)

        if frame is None:
            print("Face image could not be loaded")
            return np.zeros(12).tolist()

        faces = detector.detect_faces(frame)

        if len(faces) == 0:
            print("No face detected")
            return np.zeros(12).tolist()

        x, y, w, h, face = faces[0]

        emotion_probs = classifier.predict_emotion(face)

        v, a = va_calculator.compute(emotion_probs)
        d = distress_calculator.compute(v, a)

        landmarks = landmarks_detector.extract_landmarks(face)

        behavior_features = behavior_extractor.compute_features(landmarks)

        # =====================================================
        # VOICE PROCESSING
        # =====================================================

        audio_signal, sr = librosa.load(voice_path, sr=16000)

        energy = np.sum(audio_signal ** 2)

        mfcc = mfcc_extractor.extract(audio_signal)

        pitch = pitch_extractor.extract(audio_signal)

        pitch_series = [pitch] * 20
        amp_series = np.abs(audio_signal[:20])

        jitter, shimmer = js_extractor.compute(
            pitch_series,
            amp_series
        )

        voice_features = {
            "pitch": pitch,
            "jitter": jitter,
            "shimmer": shimmer,
            "energy": energy
        }

        voice_emotion = voice_model.compute(
            mfcc,
            pitch,
            jitter,
            shimmer,
            energy
        )

        # =====================================================
        # FEATURE FUSION
        # =====================================================

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

        print("Affect pipeline error:", e)

        return np.zeros(12).tolist()