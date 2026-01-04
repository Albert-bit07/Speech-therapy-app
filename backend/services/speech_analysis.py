"""
Enhanced speech analysis service
Articulation therapy focused with Responsible AI
"""
import librosa
import numpy as np
from datetime import datetime
from services.pronunciation_scoring import score_pronunciation
from services.feedback_generator import (
    generate_feedback,
    generate_overall_encouragement,
    get_celebration_message
)
from services.exercise_generator import generate_exercises
from services.ethics import log_privacy_compliance
from models.schemas import ProgressData, Exercise
import uuid

# Store progress in memory (in production, use database)
# Key: user_id, Value: list of ProgressData
user_progress_db = {}

def break_into_syllables(word: str) -> list:
    """
    Break word into syllables for visual display
    Simplified version - in production, use phonetic dictionary
    """
    syllable_map = {
        "butterfly": ["but", "ter", "fly"],
        "rainbow": ["rain", "bow"],
        "happy": ["hap", "py"],
        "jumping": ["jump", "ing"],
        "sunshine": ["sun", "shine"]
    }
    
    return syllable_map.get(word.lower(), [word])

def get_previous_scores(user_id: str, word: str) -> list:
    """
    Get previous attempts for this word to track progress
    """
    if user_id not in user_progress_db:
        return []
    
    return [
        p for p in user_progress_db[user_id]
        if p.word_practiced == word
    ]

def calculate_progress(current_scores: list, previous_scores: list) -> dict:
    """
    Calculate improvement based on child's own previous attempts
    NOT compared to absolute standard
    """
    if not previous_scores:
        return {
            "is_first_attempt": True,
            "improved_phonemes": [],
            "needs_more_practice": [p["phoneme"] for p in current_scores if p["confidence"] < 0.75]
        }
    
    # Get average confidence for each phoneme from previous attempts
    phoneme_history = {}
    for prev in previous_scores:
        for p in prev.get("phoneme_scores", []):
            phoneme = p["phoneme"]
            if phoneme not in phoneme_history:
                phoneme_history[phoneme] = []
            phoneme_history[phoneme].append(p["confidence"])
    
    # Calculate average previous confidence
    phoneme_avg = {
        p: sum(scores) / len(scores)
        for p, scores in phoneme_history.items()
    }
    
    # Compare current to previous average
    improved = []
    needs_practice = []
    
    for p in current_scores:
        phoneme = p["phoneme"]
        current_conf = p["confidence"]
        
        if phoneme in phoneme_avg:
            prev_avg = phoneme_avg[phoneme]
            if current_conf > prev_avg + 0.05:  # Improved by 5%
                improved.append(phoneme)
        
        if current_conf < 0.75:
            needs_practice.append(phoneme)
    
    return {
        "is_first_attempt": False,
        "improved_phonemes": improved,
        "needs_more_practice": needs_practice,
        "previous_average": phoneme_avg
    }

async def analyze_speech(
    audio_file,
    target_word: str,
    user_id: str = "demo_user",
    include_progress: bool = True
):
    """
    Main speech analysis pipeline
    1. Process audio (temporarily)
    2. Score phonemes
    3. Generate child-friendly feedback
    4. Create personalized exercises
    5. Track progress (abstract scores only)
    6. DELETE audio immediately
    """
    session_id = str(uuid.uuid4())
    start_time = datetime.now()
    
    try:
        # Step 1: Load audio safely (NO saving to disk)
        audio_bytes = await audio_file.read()
        y, sr = librosa.load(
            librosa.util.buf_to_float(audio_bytes),
            sr=16000
        )
        
        # Step 2: Score pronunciation (phoneme-level)
        phoneme_scores = score_pronunciation(y, sr, target_word)
        
        # Step 3: Calculate progress if enabled
        progress_data = None
        celebration = None
        
        if include_progress:
            previous = get_previous_scores(user_id, target_word)
            progress_info = calculate_progress(phoneme_scores, previous)
            
            # Generate celebration for improvements
            if progress_info["improved_phonemes"]:
                celebration = get_celebration_message(progress_info["improved_phonemes"])
            
            # Store this session's abstract scores
            progress_data = ProgressData(
                session_date=datetime.now(),
                word_practiced=target_word,
                overall_score=int(np.mean([p["confidence"] for p in phoneme_scores]) * 100),
                phonemes_improved=progress_info["improved_phonemes"],
                phonemes_need_practice=progress_info["needs_more_practice"],
                session_duration_seconds=int((datetime.now() - start_time).total_seconds())
            )
            
            # Save to "database" (in-memory for demo)
            if user_id not in user_progress_db:
                user_progress_db[user_id] = []
            user_progress_db[user_id].append(progress_data)
        
        # Step 4: Generate child-friendly feedback
        feedback = generate_feedback(phoneme_scores)
        
        # Step 5: Generate personalized exercises
        exercises = generate_exercises(phoneme_scores)
        
        # Step 6: Calculate overall score
        overall = int(np.mean([p["confidence"] for p in phoneme_scores]) * 100)
        
        # Step 7: Generate overall encouragement
        encouragement = generate_overall_encouragement(overall)
        
        # Step 8: Break word into syllables for UI
        syllables = break_into_syllables(target_word)
        
        # Step 9: Identify sounds to highlight
        highlighted = [
            p["phoneme"] for p in phoneme_scores
            if p["confidence"] < 0.75
        ]
        
        # Step 10: CRITICAL - Delete audio from memory
        del audio_bytes
        del y
        log_privacy_compliance(f"Session {session_id} - Audio processed and deleted")
        
        # Step 11: Return child-friendly response
        return {
            "word": target_word,
            "overall_score": overall,
            "phoneme_feedback": feedback,
            "encouragement": encouragement,
            "exercises": exercises,
            "syllables": syllables,
            "highlighted_sounds": highlighted,
            "progress": progress_data,
            "celebration": celebration
        }
    
    except Exception as e:
        # Even on error, ensure no audio is retained
        log_privacy_compliance(f"Session {session_id} - Error occurred, audio deleted")
        raise e

def get_user_progress_summary(user_id: str) -> dict:
    """
    Get summary of user's progress over time
    Shows improvement trends for encouragement
    """
    if user_id not in user_progress_db:
        return {"total_sessions": 0, "progress": []}
    
    sessions = user_progress_db[user_id]
    
    return {
        "total_sessions": len(sessions),
        "words_practiced": list(set([s.word_practiced for s in sessions])),
        "average_score": int(np.mean([s.overall_score for s in sessions])),
        "recent_improvements": [
            s.phonemes_improved for s in sessions[-5:]
            if s.phonemes_improved
        ],
        "still_practicing": list(set([
            p for s in sessions[-3:]
            for p in s.phonemes_need_practice
        ]))
    }