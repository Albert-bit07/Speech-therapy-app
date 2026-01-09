"""
Enhanced pronunciation scoring with actual phoneme detection API
Integrates with Speechace API for accurate pronunciation assessment
Falls back to mock scoring if API unavailable
"""
import os
import requests
import base64
import numpy as np
from typing import Dict, List, Tuple
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# API Configuration
SPEECHACE_API_KEY = os.getenv('SPEECHACE_API_KEY')  # Set via environment variable
SPEECHACE_API_URL = "https://api.speechace.co/api/scoring/speech/v9/json"

# Comprehensive phoneme mappings for common practice words
PHONEME_MAPS = {
    "butterfly": ["B", "AH", "T", "ER", "F", "L", "AY"],
    "rainbow": ["R", "EY", "N", "B", "OW"],
    "hi": ["HH", "AY"],
    "me": ["M", "IY"],
    "sun": ["S", "AH", "N"],
    "jumping": ["JH", "AH", "M", "P", "IH", "NG"],
    "happy": ["HH", "AE", "P", "IY"],
    "red": ["R", "EH", "D"],
    "run": ["R", "AH", "N"],
    "rain": ["R", "EY", "N"],
    "see": ["S", "IY"],
    "sit": ["S", "IH", "T"],
    "sea": ["S", "IY"],
    "think": ["TH", "IH", "NG", "K"],
    "thank": ["TH", "AE", "NG", "K"],
    "three": ["TH", "R", "IY"],
    "like": ["L", "AY", "K"],
    "let": ["L", "EH", "T"],
    "look": ["L", "UH", "K"],
    "fun": ["F", "AH", "N"],
    "find": ["F", "AY", "N", "D"],
    "fall": ["F", "AO", "L"],
    "strawberry": ["S", "T", "R", "AO", "B", "EH", "R", "IY"],
    "telephone": ["T", "EH", "L", "AH", "F", "OW", "N"],
}

# Phoneme to articulatory feature mapping
PHONEME_TO_ARTICULATOR = {
    "R": "r",
    "S": "s", 
    "TH": "th",
    "L": "l",
    "F": "f",
    "V": "v",
    # Simplified mappings
    "B": "b", "P": "p", "M": "m",
    "T": "t", "D": "d", "N": "n",
    "K": "k", "G": "g", "NG": "ng",
    "CH": "ch", "JH": "j",
    "HH": "h", "W": "w", "Y": "y",
    # Vowels typically don't need correction
    "AH": "vowel", "AE": "vowel", "EH": "vowel",
    "IH": "vowel", "IY": "vowel", "AY": "vowel",
    "OW": "vowel", "UH": "vowel", "EY": "vowel",
    "AO": "vowel", "ER": "vowel"
}

# Dialect variation exceptions (per your requirements)
DIALECT_VARIATIONS = {
    "TH": ["D", "T"],  # Common in some dialects
    "R": ["W", "AH"],  # R-colored vowel variations
    "ING": ["IN"],     # -ing to -in
}


def call_speechace_api(audio_bytes: bytes, target_word: str) -> Dict:
    """
    Call Speechace API for phoneme-level pronunciation assessment
    Returns detailed phoneme scores
    """
    if not SPEECHACE_API_KEY:
        logger.warning("SPEECHACE_API_KEY not set. Using fallback scoring.")
        return None
    
    try:
        # Encode audio to base64
        audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')
        
        # Prepare API request
        payload = {
            "user_id": "child_therapy_session",
            "audio_base64": audio_base64,
            "text": target_word,
            "question_info": "single-word",
            "include_fluency": "0",
            "include_intonation": "0",
        }
        
        headers = {
            "Content-Type": "application/json",
        }
        
        # Add API key to URL or headers based on Speechace docs
        response = requests.post(
            SPEECHACE_API_URL,
            json=payload,
            headers=headers,
            params={"key": SPEECHACE_API_KEY},
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            logger.info(f"API call successful for word: {target_word}")
            return result
        else:
            logger.error(f"API call failed: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        logger.error(f"Error calling Speechace API: {str(e)}")
        return None


def parse_speechace_response(api_response: Dict, target_word: str) -> List[Dict]:
    """
    Parse Speechace API response into our phoneme feedback format
    Maps their scores to our child-friendly confidence scores
    """
    phoneme_scores = []
    
    try:
        # Speechace returns word-level and phoneme-level scores
        word_score = api_response.get('text_score', {})
        words = word_score.get('word', [])
        
        if not words:
            return None
            
        # Get phoneme details from the first word
        word_data = words[0]
        phonemes = word_data.get('phone', [])
        
        for phone in phonemes:
            phoneme = phone.get('phone', '').upper()
            # Speechace scores are 0-100, convert to 0-1 confidence
            quality_score = phone.get('quality_score', 50) / 100.0
            
            # Apply minimum threshold - never go below 0.5 for child confidence
            confidence = max(0.50, quality_score)
            
            # Map to our simplified phoneme representation
            simple_phoneme = PHONEME_TO_ARTICULATOR.get(phoneme, phoneme.lower())
            
            phoneme_scores.append({
                "phoneme": simple_phoneme,
                "expected": simple_phoneme,
                "confidence": round(confidence, 2),
                "detected": phoneme,
                "api_score": quality_score
            })
        
        logger.info(f"Parsed {len(phoneme_scores)} phonemes from API response")
        return phoneme_scores
        
    except Exception as e:
        logger.error(f"Error parsing Speechace response: {str(e)}")
        return None


def apply_dialect_neutrality(phoneme: str, detected: str, confidence: float) -> float:
    """
    Adjust confidence scores to not penalize dialect variations
    Per your requirement: "No penalty for accents or dialects"
    """
    if phoneme in DIALECT_VARIATIONS:
        acceptable_variations = DIALECT_VARIATIONS[phoneme]
        if detected in acceptable_variations:
            # This is an acceptable dialect variation - boost confidence
            logger.info(f"Dialect variation detected: {phoneme} -> {detected} (not penalized)")
            return min(0.95, confidence + 0.15)  # Boost but cap at 0.95
    
    return confidence


def mock_score_pronunciation(audio, sr, target_word: str) -> List[Dict]:
    """
    Fallback mock scoring when API is unavailable
    Uses more realistic variability than pure random
    """
    phonemes = PHONEME_MAPS.get(target_word, ["UNK"])
    results = []
    
    # Simulate realistic difficulty patterns
    difficult_sounds = {"R", "S", "TH", "L"}
    
    for i, ph in enumerate(phonemes):
        # Base confidence varies by phoneme difficulty
        if ph in difficult_sounds:
            base_confidence = np.random.uniform(0.60, 0.85)
        else:
            base_confidence = np.random.uniform(0.75, 0.95)
        
        # Add natural variation
        confidence = round(base_confidence, 2)
        
        # Map to simple phoneme
        simple_ph = PHONEME_TO_ARTICULATOR.get(ph, ph.lower())
        
        results.append({
            "phoneme": simple_ph,
            "expected": simple_ph,
            "confidence": confidence,
            "detected": ph,
            "is_mock": True
        })
    
    logger.info(f"Mock scoring generated for {target_word}")
    return results


def score_pronunciation(audio, sr, target_word: str) -> List[Dict]:
    """
    Main scoring function - tries API first, falls back to mock
    
    Returns list of phoneme scores with confidence levels
    Each score includes:
    - phoneme: simplified representation (e.g., 'r', 's', 'th')
    - expected: what should be pronounced
    - confidence: 0.0-1.0 score
    - detected: actual phoneme detected (for debugging)
    """
    
    # Try to convert audio to bytes for API call
    try:
        import librosa
        import io
        import soundfile as sf
        
        # Create audio buffer
        buffer = io.BytesIO()
        sf.write(buffer, audio, sr, format='WAV')
        audio_bytes = buffer.getvalue()
        
        # Try API call first
        api_response = call_speechace_api(audio_bytes, target_word)
        
        if api_response:
            phoneme_scores = parse_speechace_response(api_response, target_word)
            
            if phoneme_scores:
                # Apply dialect neutrality adjustments
                for score in phoneme_scores:
                    score['confidence'] = apply_dialect_neutrality(
                        score['expected'],
                        score['detected'],
                        score['confidence']
                    )
                
                logger.info(f"Using API-based scoring for {target_word}")
                return phoneme_scores
    
    except Exception as e:
        logger.error(f"Error in API scoring path: {str(e)}")
    
    # Fallback to mock scoring
    logger.info(f"Falling back to mock scoring for {target_word}")
    return mock_score_pronunciation(audio, sr, target_word)


def validate_scoring_results(scores: List[Dict]) -> bool:
    """
    Validate that scoring results meet our quality standards
    Ensures scores make sense before showing to children
    """
    if not scores:
        return False
    
    for score in scores:
        # Check required fields
        if 'phoneme' not in score or 'confidence' not in score:
            return False
        
        # Confidence must be reasonable (0.5-1.0 for children)
        if not (0.5 <= score['confidence'] <= 1.0):
            return False
    
    return True


# For testing
if __name__ == "__main__":
    print("Pronunciation Scoring Module")
    print("=" * 50)
    print(f"API Key configured: {bool(SPEECHACE_API_KEY)}")
    print(f"Supported words: {len(PHONEME_MAPS)}")
    print(f"Sample words: {list(PHONEME_MAPS.keys())[:5]}")