import librosa
import numpy as np
from services.pronunciation_scoring import score_pronunciation
from services.feedback_generator import generate_feedback
from services.exercise_generator import generate_exercises

async def analyze_speech(audio_file, target_word):
    # Load audio safely (no saving)
    audio_bytes = await audio_file.read()
    y, sr = librosa.load(
        librosa.util.buf_to_float(audio_bytes),
        sr=16000
    )

    phoneme_scores = score_pronunciation(y, sr, target_word)
    feedback = generate_feedback(phoneme_scores)
    exercises = generate_exercises(phoneme_scores)

    overall = int(np.mean([p["confidence"] for p in phoneme_scores]) * 100)

    return {
        "word": target_word,
        "overall_score": overall,
        "phoneme_feedback": feedback,
        "encouragement": "Great try! You're getting better every time 🌟",
        "exercises": exercises
    }
 
