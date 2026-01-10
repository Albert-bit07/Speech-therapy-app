"""
iOS-Compatible Schema Models
Matches the Swift struct definitions in APIService.swift
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

# MARK: - iOS Pronunciation Result Models

class IOSPhonemeResult(BaseModel):
    """Matches Swift PhonemeResult struct"""
    phoneme: str = Field(..., description="e.g., '/r/', '/s/', '/th/'")
    position: int = Field(..., description="Position in word (0-indexed)")
    score: float = Field(..., ge=0.0, le=1.0, description="0.0 to 1.0")
    isCorrect: bool = Field(..., alias="isCorrect")
    expectedSound: Optional[str] = Field(None, alias="expectedSound")
    actualSound: Optional[str] = Field(None, alias="actualSound")
    
    class Config:
        populate_by_name = True


class IOSPronunciationMistake(BaseModel):
    """Matches Swift PronunciationMistake struct"""
    phoneme: str
    position: int
    severity: str = Field(..., description="minor, moderate, or major")
    suggestion: str = Field(..., description="How to improve")
    exampleWords: Optional[List[str]] = Field(None, alias="exampleWords")
    
    class Config:
        populate_by_name = True


class IOSPronunciationResult(BaseModel):
    """
    Main pronunciation analysis result for iOS
    Matches Swift PronunciationResult struct
    """
    overall_score: float = Field(..., ge=0.0, le=1.0, alias="overall_score")
    transcribed_text: str = Field(..., alias="transcribed_text")
    phoneme_analysis: List[IOSPhonemeResult] = Field(..., alias="phoneme_analysis")
    mistakes: List[IOSPronunciationMistake]
    feedback: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    
    class Config:
        populate_by_name = True


# MARK: - iOS Session Models

class IOSRewardsEarned(BaseModel):
    """Matches Swift RewardsEarned struct"""
    stars: int
    coins: int
    experience_points: int = Field(..., alias="experience_points")
    
    class Config:
        populate_by_name = True


class IOSPracticeSession(BaseModel):
    """Matches Swift PracticeSession struct"""
    user_id: str = Field(..., alias="user_id")
    session_id: str = Field(..., alias="session_id")
    timestamp: datetime
    word: str
    language: str
    pronunciation_result: dict = Field(..., alias="pronunciation_result")  # IOSPronunciationResult as dict
    time_spent: float = Field(..., alias="time_spent")  # Seconds
    attempt_number: int = Field(..., alias="attempt_number")
    
    class Config:
        populate_by_name = True


class IOSSessionResponse(BaseModel):
    """Matches Swift SessionResponse struct"""
    session_id: str = Field(..., alias="session_id")
    saved: bool
    rewards_earned: IOSRewardsEarned = Field(..., alias="rewards_earned")
    new_achievements: Optional[List[str]] = Field(None, alias="new_achievements")
    
    class Config:
        populate_by_name = True


# MARK: - iOS Progress Models

class IOSDailyProgress(BaseModel):
    """Matches Swift DailyProgress struct"""
    date: str  # ISO date string
    sessions_completed: int = Field(..., alias="sessions_completed")
    average_score: float = Field(..., alias="average_score")
    
    class Config:
        populate_by_name = True


class IOSUserProgress(BaseModel):
    """Matches Swift UserProgress struct"""
    user_id: str = Field(..., alias="user_id")
    total_sessions: int = Field(..., alias="total_sessions")
    total_stars: int = Field(..., alias="total_stars")
    total_coins: int = Field(..., alias="total_coins")
    current_streak: int = Field(..., alias="current_streak")
    longest_streak: int = Field(..., alias="longest_streak")
    practice_count: int = Field(..., alias="practice_count")
    average_accuracy: float = Field(..., alias="average_accuracy")
    improving_sounds: List[str] = Field(..., alias="improving_sounds")
    difficulty_sounds: List[str] = Field(..., alias="difficulty_sounds")
    weekly_progress: List[IOSDailyProgress] = Field(..., alias="weekly_progress")
    
    class Config:
        populate_by_name = True


# MARK: - iOS Exercise Models

class IOSExercise(BaseModel):
    """Matches Swift Exercise struct"""
    id: str
    word: str
    phonetic: str
    difficulty: int = Field(..., ge=1, le=5)
    target_phonemes: List[str] = Field(..., alias="target_phonemes")
    category: str
    audio_url: Optional[str] = Field(None, alias="audio_url")
    image_url: Optional[str] = Field(None, alias="image_url")
    fun_fact: Optional[str] = Field(None, alias="fun_fact")
    
    class Config:
        populate_by_name = True


# MARK: - Original Schemas (for web frontend)

class PhonemeFeedback(BaseModel):
    """Original web frontend model"""
    phoneme: str
    expected: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    tip: str
    visual_cue: str = "🎯"
    mouth_position: str = "neutral"
    needs_practice: bool = False
    encouragement: str


class Exercise(BaseModel):
    """Original web frontend model"""
    type: str
    title: str
    instruction: str
    phoneme: Optional[str] = None
    level: Optional[str] = None
    repetitions: Optional[int] = None


class ProgressData(BaseModel):
    """Original web frontend model"""
    session_date: datetime = Field(default_factory=datetime.now)
    word_practiced: str
    overall_score: int
    phonemes_improved: List[str] = Field(default_factory=list)
    phonemes_need_practice: List[str] = Field(default_factory=list)
    session_duration_seconds: Optional[int] = None


class AnalysisResponse(BaseModel):
    """Original web frontend response"""
    word: str
    overall_score: int = Field(..., ge=0, le=100)
    phoneme_feedback: List[PhonemeFeedback]
    encouragement: str
    exercises: List[Exercise]
    syllables: List[str] = Field(default_factory=list)
    highlighted_sounds: List[str] = Field(default_factory=list)
    progress: Optional[ProgressData] = None
    celebration: Optional[str] = None


class MouthPositionGuide(BaseModel):
    """Mouth position guide model"""
    phoneme: str
    position_name: str
    image_url: Optional[str] = None
    animation_key: Optional[str] = None
    description: str
    visual_cue: str


# Pre-defined mouth positions
MOUTH_POSITIONS = {
    "tongue_back": MouthPositionGuide(
        phoneme="r",
        position_name="tongue_back",
        description="Curl your tongue back like a little slide",
        visual_cue="🛝"
    ),
    "teeth_together": MouthPositionGuide(
        phoneme="s",
        position_name="teeth_together",
        description="Smile and keep your teeth together",
        visual_cue="🐍"
    ),
    "tongue_between_teeth": MouthPositionGuide(
        phoneme="th",
        position_name="tongue_between_teeth",
        description="Gently peek your tongue between your teeth",
        visual_cue="👅"
    ),
    "tongue_to_roof": MouthPositionGuide(
        phoneme="l",
        position_name="tongue_to_roof",
        description="Touch the top of your mouth with your tongue",
        visual_cue="🎵"
    ),
    "teeth_on_lip": MouthPositionGuide(
        phoneme="f",
        position_name="teeth_on_lip",
        description="Gently bite your bottom lip",
        visual_cue="🌬️"
    )
}