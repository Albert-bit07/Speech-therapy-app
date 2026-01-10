"""
SpeakBright Backend API - iOS Compatible
Matches the iOS frontend APIService.swift expectations
"""
from fastapi import FastAPI, File, UploadFile, Query, Body
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
from typing import Optional, List
from datetime import datetime
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
    target_word: str = Query(..., alias="target_word"),
    language: str = Query(default="en")
):
    """
    iOS-compatible pronunciation analysis endpoint
    
    Matches APIService.swift expectations:
    - POST /api/analyze-pronunciation
    - Multipart form with audio, target_word, language
    - Returns IOSPronunciationResult
    """
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
        transcribed_text=target_word.lower(),
        phoneme_analysis=[
            {
                "phoneme": f"/{p['phoneme']}/",
                "position": i,
                "score": p["confidence"],
                "isCorrect": p["confidence"] >= 0.75,
                "expectedSound": p["phoneme"],
                "actualSound": p["phoneme"] if p["confidence"] >= 0.75 else "?"
            }
            for i, p in enumerate(result["phoneme_feedback"])
        ],
        mistakes=[
            {
                "phoneme": f"/{p['phoneme']}/",
                "position": i,
                "severity": "major" if p["confidence"] < 0.60 else "moderate" if p["confidence"] < 0.75 else "minor",
                "suggestion": p["tip"],
                "exampleWords": ["practice", "with", "these"]
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
    summary = get_user_progress_summary(user_id)
    
    # Convert to iOS format
    ios_progress = IOSUserProgress(
        user_id=user_id,
        total_sessions=summary.get("total_sessions", 0),
        total_stars=summary.get("total_sessions", 0) * 3,  # 3 stars per session
        total_coins=summary.get("total_sessions", 0) * 10,  # 10 coins per session
        current_streak=calculate_streak(user_id),
        longest_streak=calculate_longest_streak(user_id),
        practice_count=summary.get("total_sessions", 0),
        average_accuracy=summary.get("average_score", 0) / 100.0,
        improving_sounds=list(set([
            p for recent in summary.get("recent_improvements", [])
            for p in recent
        ]))[:5],
        difficulty_sounds=summary.get("still_practicing", [])[:5],
        weekly_progress=generate_weekly_progress(user_id)
    )
    
    return ios_progress


@app.post("/api/sessions", response_model=IOSSessionResponse)
async def save_session_ios(session: IOSPracticeSession):
    """
    iOS-compatible session save endpoint
    
    Saves practice session and returns rewards
    """
    session_id = str(uuid.uuid4())
    
    # Store session
    sessions_db[session_id] = {
        "user_id": session.user_id,
        "timestamp": session.timestamp,
        "word": session.word,
        "result": session.pronunciation_result,
        "time_spent": session.time_spent
    }
    
    # Calculate rewards based on accuracy
    accuracy = session.pronunciation_result["overall_score"]
    stars = 3 if accuracy >= 0.90 else 2 if accuracy >= 0.75 else 1
    coins = int(accuracy * 100)
    xp = int(accuracy * 50)
    
    rewards = IOSRewardsEarned(
        stars=stars,
        coins=coins,
        experience_points=xp
    )
    
    # Check for new achievements
    achievements = check_achievements(session.user_id)
    
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
    count: int = Query(default=5),
    difficulty: str = Query(default="medium")
):
    """
    iOS-compatible adaptive exercises endpoint
    
    Returns exercises tailored to user's needs
    """
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
                difficulty=2 if difficulty == "medium" else 3,
                target_phonemes=[sound],
                category="practice",
                audio_url=None,
                image_url=None,
                fun_fact=f"Practice the '{sound}' sound!"
            ))
    
    # Fill remaining with random words
    default_words = ["BUTTERFLY", "JUMPING", "HAPPY", "SUNSHINE", "GARDEN"]
    for word in default_words[:count - len(exercises)]:
        exercises.append(IOSExercise(
            id=str(uuid.uuid4()),
            word=word,
            phonetic=" • ".join([word[i:i+2] for i in range(0, len(word), 2)]),
            difficulty=1 if difficulty == "easy" else 2,
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

def calculate_streak(user_id: str) -> int:
    """Calculate current practice streak"""
    # TODO: Implement actual streak calculation
    return 3


def calculate_longest_streak(user_id: str) -> int:
    """Calculate longest practice streak"""
    # TODO: Implement actual longest streak
    return 7


def generate_weekly_progress(user_id: str) -> List[dict]:
    """Generate weekly progress data"""
    from datetime import timedelta
    
    today = datetime.now()
    progress = []
    
    for i in range(7):
        date = today - timedelta(days=6-i)
        progress.append({
            "date": date.strftime("%Y-%m-%d"),
            "sessions_completed": 1 if i % 2 == 0 else 0,
            "average_score": 0.85 if i % 2 == 0 else 0.0
        })
    
    return progress


def check_achievements(user_id: str) -> List[str]:
    """Check for new achievements"""
    achievements = []
    
    # Check session count
    if user_id in sessions_db:
        session_count = len([s for s in sessions_db.values() if s["user_id"] == user_id])
        
        if session_count == 1:
            achievements.append("First Practice!")
        elif session_count == 10:
            achievements.append("Practice Master!")
        elif session_count == 50:
            achievements.append("Speech Champion!")
    
    return achievements


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