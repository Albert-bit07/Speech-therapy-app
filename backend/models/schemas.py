"""
Enhanced data schemas for SpeakBright
Includes visual cues, progress tracking, and articulation details
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class PhonemeFeedback(BaseModel):
    """
    Detailed feedback for a single phoneme/sound
    """
    phoneme: str = Field(..., description="The sound being analyzed (e.g., 'r', 's', 'th')")
    expected: str = Field(..., description="Expected pronunciation")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence score 0-1")
    tip: str = Field(..., description="Child-friendly articulation tip")
    visual_cue: str = Field(default="🎯", description="Emoji or icon for visual representation")
    mouth_position: str = Field(default="neutral", description="Mouth position guide")
    needs_practice: bool = Field(default=False, description="Whether this sound needs more practice")
    encouragement: str = Field(..., description="Personalized encouraging message")

class Exercise(BaseModel):
    """
    Single practice exercise
    """
    type: str = Field(..., description="Exercise type: warmup, articulation, coordination, challenge")
    title: str = Field(..., description="Exercise title")
    instruction: str = Field(..., description="Step-by-step instruction")
    phoneme: Optional[str] = Field(None, description="Target phoneme if articulation exercise")
    level: Optional[str] = Field(None, description="Exercise level: isolation, syllable, word, sentence")
    repetitions: Optional[int] = Field(None, description="How many times to repeat")

class ProgressData(BaseModel):
    """
    Track child's progress over time
    Stored in abstract form only (no audio)
    """
    session_date: datetime = Field(default_factory=datetime.now)
    word_practiced: str
    overall_score: int
    phonemes_improved: List[str] = Field(default_factory=list)
    phonemes_need_practice: List[str] = Field(default_factory=list)
    session_duration_seconds: Optional[int] = None

class AnalysisResponse(BaseModel):
    """
    Complete analysis response sent to frontend
    Child-friendly and encouraging
    """
    word: str = Field(..., description="Word that was practiced")
    overall_score: int = Field(..., ge=0, le=100, description="Overall score 0-100")
    phoneme_feedback: List[PhonemeFeedback] = Field(..., description="Detailed feedback per phoneme")
    encouragement: str = Field(..., description="Overall encouraging message")
    exercises: List[Exercise] = Field(..., description="Personalized practice exercises")
    
    # Visual breakdown for UI
    syllables: List[str] = Field(default_factory=list, description="Word broken into syllables")
    highlighted_sounds: List[str] = Field(default_factory=list, description="Sounds that need attention")
    
    # Progress tracking (optional)
    progress: Optional[ProgressData] = None
    celebration: Optional[str] = Field(None, description="Special message for improvements")

class MouthPositionGuide(BaseModel):
    """
    Visual guide for correct mouth position
    Used by frontend to show animations/images
    """
    phoneme: str
    position_name: str  # e.g., "tongue_back", "teeth_together"
    image_url: Optional[str] = None
    animation_key: Optional[str] = None
    description: str  # e.g., "Curl your tongue back like a slide"
    visual_cue: str  # Emoji representation

# Mouth position reference data
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

class PrivacyMetadata(BaseModel):
    """
    Privacy-compliant metadata
    NO audio or PII stored
    """
    session_id: str
    timestamp: datetime
    audio_processed: bool = True
    audio_deleted: bool = True
    scores_stored: bool = True
    coppa_compliant: bool = True
    gdpr_compliant: bool = True