"""
SpeakBright Backend API - iOS Compatible
Matches the iOS frontend APIService.swift expectations
"""
from fastapi import FastAPI, File, UploadFile, Query, Body, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from models.schemas import (
    AnalysisResponse, 
    MouthPositionGuide, 
    MOUTH_POSITIONS,
    # iOS-specific models
    IOSPronunciationResult,
    IOSUserProgress,
    IOSPracticeSession,
    IOSSessionResponse,
    IOSExercise,
    IOSRewardsEarned
)
from services.speech_analysis import analyze_speech, get_user_progress_summary
from services.exercise_generator import get_home_practice_tips, generate_exercises
from typing import Optional, List, Literal
from datetime import datetime, timedelta, timezone
import uuid

app = FastAPI(
    title="SpeakBright Backend",
    version="2.0",
    description="AI-powered speech therapy for children - iOS Compatible"
)

# CORS for iOS app (IMPORTANT!)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # iOS app can connect
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for iOS sessions (use database in production)
sessions_db = {}
exercises_db = {}

# MARK: - iOS Compatible Endpoints

@app.post("/api/analyze-pronunciation", response_model=IOSPronunciationResult)
async def analyze_pronunciation_ios(
    audio: UploadFile = File(...),
    target_word: Optional[str] = Form(default=None),
    language: str = Form(default="en"),
    query_target_word: Optional[str] = Query(default=None, alias="target_word"),
    query_language: Optional[str] = Query(default=None, alias="language")
):
    """
    iOS-compatible pronunciation analysis endpoint
    
    Matches APIService.swift expectations:
    - POST /api/analyze-pronunciation
    - Multipart form with audio, target_word, language
    - Returns IOSPronunciationResult
    """
    target_word = (target_word if target_word is not None else query_target_word or "").strip()
    if not target_word or len(target_word) > 100:
        raise HTTPException(status_code=422, detail="target_word must contain 1-100 characters")
    if (query_language or language) != "en":
        raise HTTPException(status_code=422, detail="Only English analysis is supported")
    # Use our existing analysis but adapt response
    result = await analyze_speech(
        audio,
        target_word,
        user_id="ios_user",  # Could extract from auth header
        include_progress=False
    )
    
    # Convert to iOS format
    ios_result = IOSPronunciationResult(
        overall_score=result["overall_score"] / 100.0,  # Convert to 0-1
        transcribed_text=result.get("transcribed_text", ""),
        phoneme_analysis=[
            {
                "phoneme": f"/{p['phoneme']}/",
                "position": i,
                "score": p["confidence"],
                "isCorrect": p["confidence"] >= 0.75,
                "expectedSound": p["phoneme"],
                "actualSound": p.get("detected", "")
            }
            for i, p in enumerate(result["phoneme_feedback"])
        ],
        mistakes=[
            {
                "phoneme": f"/{p['phoneme']}/",
                "position": i,
                "severity": "major" if p["confidence"] < 0.60 else "moderate" if p["confidence"] < 0.75 else "minor",
                "suggestion": p["tip"],
                "exampleWords": []
            }
            for i, p in enumerate(result["phoneme_feedback"])
            if p["needs_practice"]
        ],
        feedback=result["encouragement"],
        confidence=sum(p["confidence"] for p in result["phoneme_feedback"]) / len(result["phoneme_feedback"])
    )
    
    return ios_result


@app.get("/api/progress/{user_id}", response_model=IOSUserProgress)
async def get_progress_ios(user_id: str):
    """
    iOS-compatible progress endpoint
    
    Returns comprehensive user progress data
    """
    sessions = user_sessions(user_id)
    scores = [session['result']['overall_score'] for session in sessions]
    ios_progress = IOSUserProgress(
        user_id=user_id,
        total_sessions=len(sessions),
        total_stars=sum(rewards_for(score)['stars'] for score in scores),
        total_coins=sum(rewards_for(score)['coins'] for score in scores),
        current_streak=calculate_streak(user_id),
        longest_streak=calculate_longest_streak(user_id),
        practice_count=len(sessions),
        average_accuracy=sum(scores) / len(scores) if scores else 0,
        improving_sounds=[],
        difficulty_sounds=[],
        weekly_progress=generate_weekly_progress(user_id)
    )

    return ios_progress


@app.post("/api/sessions", response_model=IOSSessionResponse)
async def save_session_ios(session: IOSPracticeSession):
    """
    iOS-compatible session save endpoint
    
    Saves practice session and returns rewards
    """
    accuracy = session.pronunciation_result.get('overall_score')
    import math
    if isinstance(accuracy, bool) or not isinstance(accuracy, (int, float)) or not math.isfinite(accuracy) or not 0 <= accuracy <= 1:
        raise HTTPException(status_code=422, detail='overall_score must be finite and between 0 and 1')
    if session.time_spent < 0 or not math.isfinite(session.time_spent) or session.attempt_number < 1:
        raise HTTPException(status_code=422, detail='Invalid session duration or attempt number')
    if not session.user_id.strip() or not session.session_id.strip():
        raise HTTPException(status_code=422, detail='User and session IDs must not be empty')
    timestamp = session.timestamp.replace(tzinfo=timezone.utc) if session.timestamp.tzinfo is None else session.timestamp.astimezone(timezone.utc)
    if timestamp > datetime.now(timezone.utc) + timedelta(minutes=5):
        raise HTTPException(status_code=422, detail='Session timestamp is in the future')
    session_id = session.session_id
    key = (session.user_id, session_id)
    record = {
        'user_id': session.user_id, 'timestamp': timestamp, 'word': session.word,
        'result': session.pronunciation_result, 'time_spent': session.time_spent,
        'language': session.language, 'attempt_number': session.attempt_number,
    }
    previous = sessions_db.get(key)
    if previous is not None and previous != record:
        raise HTTPException(status_code=409, detail='Session ID already used for different content')
    sessions_db[key] = record
    rewards = IOSRewardsEarned(**rewards_for(accuracy))

    # Check for new achievements
    achievements = [] if previous is not None else check_achievements(session.user_id)
    
    response = IOSSessionResponse(
        session_id=session_id,
        saved=True,
        rewards_earned=rewards,
        new_achievements=achievements
    )
    
    return response


@app.get("/api/exercises/adaptive", response_model=List[IOSExercise])
async def get_adaptive_exercises_ios(
    user_id: str = Query(...),
    count: int = Query(default=5, ge=1, le=5),
    difficulty: Literal["easy", "medium", "hard"] = Query(default="medium")
):
    """
    iOS-compatible adaptive exercises endpoint
    
    Returns exercises tailored to user's needs
    """
    difficulty_level = {"easy": 1, "medium": 2, "hard": 3}[difficulty]
    # Get user's difficulty areas
    summary = get_user_progress_summary(user_id)
    difficult_sounds = summary.get("still_practicing", [])
    
    # Generate exercises focusing on difficult sounds
    exercises = []
    
    words_by_sound = {
        "r": ["rainbow", "rocket", "rabbit"],
        "s": ["sun", "sea", "snake"],
        "th": ["think", "three", "thumb"],
        "l": ["lion", "lemon", "lake"],
        "f": ["fish", "flower", "frog"]
    }
    
    # Start with difficult sounds
    for sound in difficult_sounds[:count]:
        if sound in words_by_sound:
            word = words_by_sound[sound][0]
            exercises.append(IOSExercise(
                id=str(uuid.uuid4()),
                word=word.upper(),
                phonetic=f"{word[0]} • {word[1:]}",
                difficulty=difficulty_level,
                target_phonemes=[sound],
                category="practice",
                audio_url=None,
                image_url=None,
                fun_fact=f"Practice the '{sound}' sound!"
            ))
    
    # Fill remaining slots from the fixed fallback catalog
    default_words = ["BUTTERFLY", "JUMPING", "HAPPY", "SUNSHINE", "GARDEN"]
    for word in default_words[:count - len(exercises)]:
        exercises.append(IOSExercise(
            id=str(uuid.uuid4()),
            word=word,
            phonetic=" • ".join([word[i:i+2] for i in range(0, len(word), 2)]),
            difficulty=difficulty_level,
            target_phonemes=["mixed"],
            category="general",
            audio_url=None,
            image_url=None,
            fun_fact=f"A fun word to practice!"
        ))
    
    return exercises[:count]


# MARK: - Original Endpoints (kept for compatibility)

@app.get("/")
async def root():
    """
    API health check
    """
    return {
        "service": "SpeakBright API",
        "version": "2.0-iOS",
        "status": "online",
        "ios_compatible": True,
        "endpoints": {
            "ios": [
                "POST /api/analyze-pronunciation",
                "GET /api/progress/{user_id}",
                "POST /api/sessions",
                "GET /api/exercises/adaptive"
            ],
            "web": [
                "POST /analyze",
                "GET /progress/{user_id}",
                "GET /mouth-guide/{phoneme}",
                "GET /home-tips/{phoneme}",
                "GET /words",
                "GET /ethics"
            ]
        }
    }


@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_pronunciation_web(
    audio: UploadFile = File(...),
    target_word: str = Query(default="butterfly"),
    user_id: str = Query(default="demo_user"),
    track_progress: bool = Query(default=True)
):
    """
    Web-compatible pronunciation analysis
    (Original endpoint for web frontend)
    """
    result = await analyze_speech(
        audio,
        target_word,
        user_id=user_id,
        include_progress=track_progress
    )
    return result


@app.get("/progress/{user_id}")
async def get_progress_web(user_id: str):
    """
    Web-compatible progress endpoint
    """
    summary = get_user_progress_summary(user_id)
    return {
        "user_id": user_id,
        "summary": summary,
        "privacy_note": "Only abstract scores stored. No audio retained."
    }


@app.get("/mouth-guide/{phoneme}", response_model=MouthPositionGuide)
async def get_mouth_guide(phoneme: str):
    """
    Get mouth position guide for a specific phoneme
    """
    position_key = {
        "r": "tongue_back",
        "s": "teeth_together",
        "th": "tongue_between_teeth",
        "l": "tongue_to_roof",
        "f": "teeth_on_lip",
        "v": "teeth_on_lip"
    }.get(phoneme.lower(), "neutral")
    
    if position_key in MOUTH_POSITIONS:
        return MOUTH_POSITIONS[position_key]
    
    return MouthPositionGuide(
        phoneme=phoneme,
        position_name="neutral",
        description="Keep practicing! You're doing great!",
        visual_cue="✨"
    )


@app.get("/home-tips/{phoneme}")
async def get_home_tips(phoneme: str):
    """
    Get home practice tips for parents
    """
    tips = get_home_practice_tips(phoneme)
    return {
        "phoneme": phoneme,
        "tips": tips,
        "note": "Practice should be fun and positive! 5-10 minutes is plenty."
    }


@app.get("/words")
async def get_practice_words():
    """
    Get list of available practice words
    """
    return {
        "beginner": [
            {"word": "hi", "phonemes": ["h", "ai"]},
            {"word": "me", "phonemes": ["m", "ee"]},
            {"word": "sun", "phonemes": ["s", "uh", "n"]}
        ],
        "intermediate": [
            {"word": "rainbow", "phonemes": ["r", "ai", "n", "b", "oh"]},
            {"word": "butterfly", "phonemes": ["b", "uh", "t", "er", "f", "l", "ai"]},
            {"word": "jumping", "phonemes": ["j", "uh", "m", "p", "ih", "ng"]}
        ],
        "advanced": [
            {"word": "strawberry", "phonemes": ["s", "t", "r", "aw", "b", "eh", "r", "ee"]},
            {"word": "telephone", "phonemes": ["t", "eh", "l", "uh", "f", "oh", "n"]}
        ]
    }


@app.get("/ethics")
async def get_ethics_info():
    """
    Responsible AI principles
    """
    return {
        "principles": {
            "no_harsh_feedback": "We never use words like 'wrong' or 'bad'",
            "encourage_effort": "We celebrate trying, not just perfection",
            "explain_gently": "We show HOW to improve, not what's 'wrong'",
            "privacy_first": "Audio is deleted immediately after processing",
            "progress_based": "We compare to the child's own progress, not others",
            "accent_neutral": "We don't penalize regional accents or dialects",
            "age_appropriate": "All language is child-friendly and encouraging"
        }
    }


@app.get("/health")
async def health_check():
    """
    Health check for monitoring
    """
    return {
        "status": "healthy",
        "service": "SpeakBright",
        "ios_compatible": True,
        "privacy_compliant": True
    }


# MARK: - Helper Functions

def user_sessions(user_id: str) -> list:
    return [session for session in sessions_db.values() if session['user_id'] == user_id]


def rewards_for(score: float) -> dict:
    return {'stars': 3 if score >= 0.90 else 2 if score >= 0.75 else 1,
            'coins': int(score * 100), 'experience_points': int(score * 50)}


def practice_dates(user_id: str) -> set:
    return {session['timestamp'].date() for session in user_sessions(user_id)}


def calculate_streak(user_id: str, today=None) -> int:
    today = today or datetime.now(timezone.utc).date()
    dates = practice_dates(user_id)
    cursor = today if today in dates else today - timedelta(days=1)
    streak = 0
    while cursor in dates:
        streak += 1
        cursor -= timedelta(days=1)
    return streak


def calculate_longest_streak(user_id: str) -> int:
    longest = current = 0
    previous = None
    for day in sorted(practice_dates(user_id)):
        current = current + 1 if previous is not None and day - previous == timedelta(days=1) else 1
        longest = max(longest, current)
        previous = day
    return longest


def generate_weekly_progress(user_id: str, today=None) -> List[dict]:
    today = today or datetime.now(timezone.utc).date()
    sessions = user_sessions(user_id)
    progress = []
    for offset in range(6, -1, -1):
        day = today - timedelta(days=offset)
        scores = [session['result']['overall_score'] for session in sessions if session['timestamp'].date() == day]
        progress.append({'date': day.isoformat(), 'sessions_completed': len(scores),
                         'average_score': sum(scores) / len(scores) if scores else 0})
    return progress


def check_achievements(user_id: str) -> List[str]:
    milestones = {1: 'First Practice!', 10: 'Practice Master!', 50: 'Speech Champion!'}
    achievement = milestones.get(len(user_sessions(user_id)))
    return [achievement] if achievement else []


# MARK: - Startup

if __name__ == "__main__":
    import uvicorn
    print("=" * 60)
    print("🌟 SpeakBright Backend Starting...")
    print("📱 iOS Compatible Mode")
    print("🔒 Privacy-First (No Audio Storage)")
    print("👶 Child-Friendly AI")
    print("=" * 60)
    print(f"iOS Endpoints:")
    print(f"  POST http://localhost:8000/api/analyze-pronunciation")
    print(f"  GET  http://localhost:8000/api/progress/{{user_id}}")
    print(f"  POST http://localhost:8000/api/sessions")
    print(f"  GET  http://localhost:8000/api/exercises/adaptive")
    print("=" * 60)
    print(f"API Docs: http://localhost:8000/docs")
    print(f"Health: http://localhost:8000/health")
    print("=" * 60)
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )