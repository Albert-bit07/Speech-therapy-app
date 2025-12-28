from fastapi import FastAPI, File, UploadFile
from models.schemas import AnalysisResponse
from services.speech_analysis import analyze_speech

app = FastAPI(title="SpeakBright Backend", version="1.0")

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_pronunciation(
    audio: UploadFile = File(...),
    target_word: str = "butterfly"
):
    """
    Analyze pronunciation and return explainable feedback.
    No raw audio is stored (Responsible AI).
    """
    result = await analyze_speech(audio, target_word)
    return result
 
