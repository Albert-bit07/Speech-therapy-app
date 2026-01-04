"""
SpeakBright Backend API
Child-focused speech therapy with Responsible AI
"""
from fastapi import FastAPI, File, UploadFile, Query
from fastapi.middleware.cors import CORSMiddleware
from models.schemas import AnalysisResponse, MouthPositionGuide, MOUTH_POSITIONS
from services.speech_analysis import analyze_speech, get_user_progress_summary
from services.exercise_generator import get_home_practice_tips
from typing import Optional

app = FastAPI(
    title="SpeakBright Backend",
    version="2.0",
    description="AI-powered speech therapy for children - Articulation focused"
)

# CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """
    API health check
    """
    return {
        "service": "SpeakBright API",
        "version": "2.0",
        "status": "online",
        "features": [
            "Articulation therapy",
            "Child-friendly feedback",
            "Progress tracking",
            "Privacy-first (no audio storage)",
            "COPPA & GDPR compliant"
        ]
    }

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_pronunciation(
    audio: UploadFile = File(...),
    target_word: str = Query(default="butterfly", description="Word to practice"),
    user_id: str = Query(default="demo_user", description="User identifier"),
    track_progress: bool = Query(default=True, description="Track progress over time")
):
    """
    Analyze pronunciation and return child-friendly feedback
    
    Features:
    - Phoneme-level scoring
    - Gentle, encouraging feedback
    - Personalized exercises
    - Progress tracking (abstract scores only)
    - NO raw audio stored (Responsible AI)
    - COPPA & GDPR compliant
    
    Returns:
    - Overall score (0-100)
    - Detailed phoneme feedback with visual cues
    - Articulation exercises
    - Encouraging messages
    - Progress data (if enabled)
    """
    result = await analyze_speech(
        audio,
        target_word,
        user_id=user_id,
        include_progress=track_progress
    )
    return result

@app.get("/progress/{user_id}")
async def get_progress(user_id: str):
    """
    Get user's progress summary
    Shows improvement over time for encouragement
    
    Privacy: Only abstract scores stored, no audio or PII
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
    Returns visual cues and descriptions for correct articulation
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
    Evidence-based guidance for supporting practice at home
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
    Organized by difficulty level
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
            {"word": "telephone", "phonemes": ["t", "eh", "l", "uh", "f", "oh", "n"]},
            {"word": "refrigerator", "phonemes": ["r", "ih", "f", "r", "ih", "j", "er", "ai", "t", "er"]}
        ]
    }

@app.get("/ethics")
async def get_ethics_info():
    """
    Information about our Responsible AI principles
    Transparency for parents and educators
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
        },
        "privacy": {
            "audio_retention": "0 seconds - deleted immediately",
            "data_stored": "Only abstract scores for progress tracking",
            "compliance": ["COPPA", "GDPR data minimization"],
            "no_pii": "No personally identifiable information stored"
        },
        "therapy_approach": {
            "focus": "Articulation therapy (speech sound production)",
            "method": "Evidence-based speech therapy techniques",
            "progression": "Isolation → Syllable → Word → Sentence",
            "individualized": "Exercises adapt to each child's needs"
        }
    }

@app.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring
    """
    return {
        "status": "healthy",
        "service": "SpeakBright",
        "privacy_compliant": True
    }

if __name__ == "__main__":
    import uvicorn
    print("=" * 60)
    print("🌟 SpeakBright Backend Starting...")
    print("📚 Articulation Therapy API")
    print("🔒 Privacy-First (No Audio Storage)")
    print("👶 Child-Friendly AI")
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