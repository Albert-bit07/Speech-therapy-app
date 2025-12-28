from pydantic import BaseModel
from typing import List

class PhonemeFeedback(BaseModel):
    phoneme: str
    expected: str
    confidence: float
    tip: str

class AnalysisResponse(BaseModel):
    word: str
    overall_score: int
    phoneme_feedback: List[PhonemeFeedback]
    encouragement: str
    exercises: List[str]
 
