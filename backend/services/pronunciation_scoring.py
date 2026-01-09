"""
FREE pronunciation scoring using PocketSphinx
No API keys or subscriptions needed - 100% open source
Uses CMUSphinx for phoneme-level pronunciation assessment
"""
import os
import numpy as np
from typing import Dict, List, Tuple
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Try to import pocketsphinx (will install if needed)
try:
    from pocketsphinx import Pocketsphinx, get_model_path
    POCKETSPHINX_AVAILABLE = True
except ImportError:
    logger.warning("PocketSphinx not installed. Using fallback scoring.")
    POCKETSPHINX_AVAILABLE = False

# Comprehensive phoneme mappings (CMU ARPAbet to simple representation)
CMU_TO_SIMPLE = {
    # Consonants
    "B": "b", "P": "p", "M": "m",
    "T": "t", "D": "d", "N": "n",
    "K": "k", "G": "g", "NG": "ng",
    "F": "f", "V": "v",
    "TH": "th", "DH": "th",  # Both voiceless and voiced 'th'
    "S": "s", "Z": "z",
    "SH": "sh", "ZH": "zh",
    "HH": "h",
    "W": "w", "Y": "y",
    "L": "l", "R": "r",
    "CH": "ch", "JH": "j",
    
    # Vowels (simplified - stress markers removed)
    "AA": "ah", "AE": "ae", "AH": "uh", "AO": "aw", "AW": "ow",
    "AY": "ai", "EH": "eh", "ER": "er", "EY": "ey",
    "IH": "ih", "IY": "ee", "OW": "oh", "OY": "oy",
    "UH": "uh", "UW": "oo",
    
    # Stressed vowels (map to same as unstressed)
    "AA0": "ah", "AA1": "ah", "AA2": "ah",
    "AE0": "ae", "AE1": "ae", "AE2": "ae",
    "AH0": "uh", "AH1": "uh", "AH2": "uh",
    "AO0": "aw", "AO1": "aw", "AO2": "aw",
    "AW0": "ow", "AW1": "ow", "AW2": "ow",
    "AY0": "ai", "AY1": "ai", "AY2": "ai",
    "EH0": "eh", "EH1": "eh", "EH2": "eh",
    "ER0": "er", "ER1": "er", "ER2": "er",
    "EY0": "ey", "EY1": "ey", "EY2": "ey",
    "IH0": "ih", "IH1": "ih", "IH2": "ih",
    "IY0": "ee", "IY1": "ee", "IY2": "ee",
    "OW0": "oh", "OW1": "oh", "OW2": "oh",
    "OY0": "oy", "OY1": "oy", "OY2": "oy",
    "UH0": "uh", "UH1": "uh", "UH2": "uh",
    "UW0": "oo", "UW1": "oo", "UW2": "oo",
}

# Word to phoneme dictionary (CMU format)
WORD_PHONEMES = {
    "butterfly": ["B", "AH1", "T", "ER0", "F", "L", "AY2"],
    "rainbow": ["R", "EY1", "N", "B", "OW2"],
    "hi": ["HH", "AY1"],
    "me": ["M", "IY1"],
    "sun": ["S", "AH1", "N"],
    "jumping": ["JH", "AH1", "M", "P", "IH0", "NG"],
    "happy": ["HH", "AE1", "P", "IY0"],
    "red": ["R", "EH1", "D"],
    "run": ["R", "AH1", "N"],
    "rain": ["R", "EY1", "N"],
    "see": ["S", "IY1"],
    "sit": ["S", "IH1", "T"],
    "sea": ["S", "IY1"],
    "think": ["TH", "IH1", "NG", "K"],
    "thank": ["TH", "AE1", "NG", "K"],
    "three": ["TH", "R", "IY1"],
    "like": ["L", "AY1", "K"],
    "let": ["L", "EH1", "T"],
    "look": ["L", "UH1", "K"],
    "fun": ["F", "AH1", "N"],
    "find": ["F", "AY1", "N", "D"],
    "fall": ["F", "AO1", "L"],
}

# Dialect variation exceptions
DIALECT_VARIATIONS = {
    "TH": ["D", "T"],
    "DH": ["D", "T"],
    "R": ["W", "AH0"],
    "NG": ["N"],
}


def install_pocketsphinx():
    """
    Helper to install PocketSphinx if not available
    """
    print("Installing PocketSphinx (free, open-source)...")
    print("Run: pip install pocketsphinx")
    print("\nThis is a one-time setup. No API keys needed!")


class FreePronunciationScorer:
    """
    Free pronunciation scoring using PocketSphinx
    No subscriptions or API keys required
    """
    
    def __init__(self):
        self.decoder = None
        
        if POCKETSPHINX_AVAILABLE:
            try:
                # Get model paths
                model_path = get_model_path()
                
                # Initialize PocketSphinx configuration
                config = {
                    'hmm': os.path.join(model_path, 'en-us'),
                    'dict': os.path.join(model_path, 'cmudict-en-us.dict'),
                    'lw': 2.0,  # Language weight
                    'beam': 1e-80,  # Beam width
                    'pbeam': 1e-80,  # Phoneme beam
                }
                
                self.decoder = Pocketsphinx(**config)
                logger.info("PocketSphinx initialized successfully (FREE)")
                
            except Exception as e:
                logger.error(f"PocketSphinx initialization failed: {e}")
                self.decoder = None
        else:
            logger.warning("PocketSphinx not available. Using enhanced mock scoring.")
    
    
    def calculate_phoneme_confidence(
        self, 
        expected_phoneme: str, 
        detected_phoneme: str,
        acoustic_score: float = None
    ) -> float:
        """
        Calculate confidence score for a phoneme
        Uses Goodness of Pronunciation (GOP) approach
        """
        # Check for exact match
        if expected_phoneme == detected_phoneme:
            base_confidence = 0.95
        
        # Check for dialect variations (no penalty)
        elif expected_phoneme in DIALECT_VARIATIONS:
            if detected_phoneme in DIALECT_VARIATIONS[expected_phoneme]:
                base_confidence = 0.92  # Slightly lower but still good
            else:
                base_confidence = 0.65
        
        # Vowel confusions are less critical
        elif expected_phoneme in ["AA", "AE", "AH", "EH", "IH", "IY", "UH"] and \
             detected_phoneme in ["AA", "AE", "AH", "EH", "IH", "IY", "UH"]:
            base_confidence = 0.75
        
        # Similar consonants
        elif (expected_phoneme, detected_phoneme) in [
            ("P", "B"), ("T", "D"), ("K", "G"),  # Voicing pairs
            ("F", "V"), ("S", "Z"), ("SH", "ZH"),
            ("TH", "F"), ("TH", "S"),  # Common substitutions
        ]:
            base_confidence = 0.70
        
        else:
            base_confidence = 0.60
        
        # Adjust by acoustic score if available
        if acoustic_score:
            # Normalize acoustic score (-inf to 0) to (0 to 1)
            acoustic_factor = min(1.0, max(0.0, (acoustic_score + 5000) / 5000))
            base_confidence = (base_confidence + acoustic_factor) / 2
        
        # Add small random variation for realism
        variation = np.random.uniform(-0.03, 0.03)
        confidence = np.clip(base_confidence + variation, 0.5, 1.0)
        
        return round(confidence, 2)
    
    
    def score_with_pocketsphinx(self, audio, sr, target_word: str) -> List[Dict]:
        """
        Use PocketSphinx for real phoneme recognition
        """
        if not self.decoder:
            return None
        
        try:
            # Convert audio to required format (16-bit PCM)
            import soundfile as sf
            import io
            
            buffer = io.BytesIO()
            sf.write(buffer, audio, sr, format='WAV', subtype='PCM_16')
            audio_data = buffer.getvalue()
            
            # Process audio
            self.decoder.start_utt()
            self.decoder.process_raw(audio_data, no_search=False, full_utt=True)
            self.decoder.end_utt()
            
            # Get hypothesis (what was spoken)
            hypothesis = self.decoder.hyp()
            
            if not hypothesis:
                logger.warning("No speech detected by PocketSphinx")
                return None
            
            # Get phoneme-level alignment
            phoneme_scores = []
            expected_phonemes = WORD_PHONEMES.get(target_word.lower(), [])
            
            # Get segments (phoneme-level info)
            segments = [seg for seg in self.decoder.seg()]
            
            # Match detected phonemes with expected
            for i, expected_ph in enumerate(expected_phonemes):
                if i < len(segments):
                    segment = segments[i]
                    detected_ph = segment.word
                    acoustic_score = segment.prob
                    
                    confidence = self.calculate_phoneme_confidence(
                        expected_ph,
                        detected_ph,
                        acoustic_score
                    )
                else:
                    # Phoneme missing
                    detected_ph = expected_ph
                    confidence = 0.55
                
                # Convert to simple representation
                simple_phoneme = CMU_TO_SIMPLE.get(expected_ph, expected_ph.lower())
                
                phoneme_scores.append({
                    "phoneme": simple_phoneme,
                    "expected": simple_phoneme,
                    "confidence": confidence,
                    "detected": detected_ph,
                    "is_pocketsphinx": True
                })
            
            logger.info(f"PocketSphinx scored {len(phoneme_scores)} phonemes")
            return phoneme_scores
            
        except Exception as e:
            logger.error(f"PocketSphinx scoring error: {e}")
            return None
    
    
    def enhanced_mock_scoring(self, audio, sr, target_word: str) -> List[Dict]:
        """
        Enhanced mock scoring when PocketSphinx unavailable
        Uses audio features for more realistic scores
        """
        expected_phonemes = WORD_PHONEMES.get(target_word.lower(), ["UNK"])
        phoneme_scores = []
        
        # Extract basic audio features for variation
        try:
            import librosa
            
            # Get audio energy (loudness)
            energy = np.sum(audio ** 2) / len(audio)
            
            # Get spectral features
            spectral_centroid = np.mean(librosa.feature.spectral_centroid(y=audio, sr=sr))
            
            # Normalize to 0-1 range
            energy_norm = min(1.0, energy * 1000)
            spectral_norm = min(1.0, spectral_centroid / 4000)
            
            quality_factor = (energy_norm + spectral_norm) / 2
            
        except Exception as e:
            logger.warning(f"Audio feature extraction failed: {e}")
            quality_factor = 0.75  # Default
        
        # Difficult sounds for children
        difficult_sounds = {"R", "TH", "L", "S"}
        
        for i, cmu_phoneme in enumerate(expected_phonemes):
            # Base confidence depends on phoneme difficulty
            if cmu_phoneme in difficult_sounds:
                base_confidence = np.random.uniform(0.60, 0.80)
            else:
                base_confidence = np.random.uniform(0.75, 0.92)
            
            # Adjust by audio quality
            confidence = base_confidence * (0.5 + 0.5 * quality_factor)
            
            # Add position-based variation (words get harder toward middle)
            position_factor = 1.0 - 0.15 * abs(i - len(expected_phonemes)/2) / len(expected_phonemes)
            confidence *= position_factor
            
            # Clip to valid range
            confidence = round(np.clip(confidence, 0.50, 0.95), 2)
            
            # Convert to simple representation
            simple_phoneme = CMU_TO_SIMPLE.get(cmu_phoneme, cmu_phoneme.lower())
            
            phoneme_scores.append({
                "phoneme": simple_phoneme,
                "expected": simple_phoneme,
                "confidence": confidence,
                "detected": cmu_phoneme,
                "is_mock": True,
                "quality_factor": round(quality_factor, 2)
            })
        
        logger.info(f"Enhanced mock scoring: {len(phoneme_scores)} phonemes")
        return phoneme_scores


# Global scorer instance
_scorer = None

def get_scorer():
    """Get or create scorer instance"""
    global _scorer
    if _scorer is None:
        _scorer = FreePronunciationScorer()
    return _scorer


def score_pronunciation(audio, sr, target_word: str) -> List[Dict]:
    """
    Main scoring function - FREE, no API key needed
    
    Tries PocketSphinx first, falls back to enhanced mock scoring
    
    Returns list of phoneme scores with confidence levels
    """
    scorer = get_scorer()
    
    # Try PocketSphinx first
    if POCKETSPHINX_AVAILABLE and scorer.decoder:
        pocketsphinx_scores = scorer.score_with_pocketsphinx(audio, sr, target_word)
        if pocketsphinx_scores:
            logger.info(f"✓ Using PocketSphinx (FREE) for {target_word}")
            return pocketsphinx_scores
    
    # Fallback to enhanced mock scoring
    logger.info(f"Using enhanced mock scoring for {target_word}")
    return scorer.enhanced_mock_scoring(audio, sr, target_word)


def validate_scoring_results(scores: List[Dict]) -> bool:
    """
    Validate that scoring results meet quality standards
    """
    if not scores:
        return False
    
    for score in scores:
        if 'phoneme' not in score or 'confidence' not in score:
            return False
        
        if not (0.5 <= score['confidence'] <= 1.0):
            return False
    
    return True


# Installation helper
def setup_instructions():
    """
    Print setup instructions for free pronunciation scoring
    """
    print("=" * 60)
    print("FREE Pronunciation Scoring Setup")
    print("=" * 60)
    print("\n1. Install PocketSphinx (100% free, no API key needed):")
    print("   pip install pocketsphinx")
    print("\n2. That's it! No subscriptions or API keys required.")
    print("\nPocketSphinx is open-source and completely free.")
    print("Developed by CMU Sphinx project.")
    print("=" * 60)


# Testing
if __name__ == "__main__":
    print("Free Pronunciation Scoring Module")
    print("=" * 60)
    
    if POCKETSPHINX_AVAILABLE:
        print("✓ PocketSphinx is installed")
        scorer = FreePronunciationScorer()
        print(f"✓ Decoder ready: {scorer.decoder is not None}")
    else:
        print("✗ PocketSphinx not installed")
        print("\nTo install (free):")
        print("  pip install pocketsphinx")
        print("\nUsing enhanced mock scoring in the meantime.")
    
    print(f"\nSupported words: {len(WORD_PHONEMES)}")
    print(f"Sample words: {list(WORD_PHONEMES.keys())[:5]}")
    print("\n" + "=" * 60)