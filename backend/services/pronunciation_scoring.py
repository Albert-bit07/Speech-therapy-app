"""
FREE pronunciation scoring using PocketSphinx
No API keys or subscriptions needed - 100% open source
Experimental decoder-segment comparison; not validated phoneme alignment
"""
import os
import threading
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
    logger.warning("PocketSphinx not installed. Pronunciation scoring is unavailable.")
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
        self._decode_lock = threading.Lock()
        
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
            logger.warning("PocketSphinx not available. Pronunciation scoring is unavailable.")
    
    
    def calculate_phoneme_confidence(
        self, 
        expected_phoneme: str, 
        detected_phoneme: str,
        acoustic_score: float = None
    ) -> float:
        """
        Calculate confidence score for a phoneme
        Heuristic similarity mapping; not calibrated Goodness of Pronunciation
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
        
        return round(float(np.clip(base_confidence, 0.5, 1.0)), 2)

    
    def score_with_pocketsphinx(self, audio, sr, target_word: str) -> List[Dict]:
        """Serialize utterances: a decoder owns mutable search and result state."""
        samples = np.asarray(audio)
        if sr != 16000 or samples.ndim != 1 or not samples.size:
            raise ValueError("Expected nonempty mono audio at 16000 Hz")
        if not np.isfinite(samples).all():
            raise ValueError("Audio samples must be finite")
        # process_raw accepts signed PCM samples, not a WAV container. Saturate
        # before conversion so +1.0 cannot wrap around to a negative sample.
        pcm = np.clip(np.rint(samples * 32768.0), -32768, 32767).astype("<i2").tobytes()
        with self._decode_lock:
            if self.decoder is None:
                raise ScoringUnavailable("Pronunciation recognizer is unavailable")
            return self._score_pcm(pcm, target_word)

    def _score_pcm(self, audio_data: bytes, target_word: str) -> List[Dict]:
        try:
            self.decoder.start_utt()
            try:
                self.decoder.process_raw(audio_data, no_search=False, full_utt=True)
            finally:
                # Close an opened utterance even if native decoding fails.
                self.decoder.end_utt()

            # Get hypothesis (what was spoken)
            hypothesis = self.decoder.hyp()
            
            if not hypothesis:
                logger.warning("No speech detected by PocketSphinx")
                return None
            
            # This decoder runs word search. Even labels that resemble ARPAbet
            # are not evidence of phoneme alignment. Never fill missing phones
            # from the target or turn word posteriors into assessment scores.
            raise ScoringUnavailable("Phoneme assessment is not implemented")

        except ScoringUnavailable:
            raise
        except Exception as e:
            logger.exception("PocketSphinx scoring failed")
            raise ScoringUnavailable("Pronunciation decoder failed") from e
    
    
# Global scorer instance
_scorer = None

def get_scorer():
    """Get or create scorer instance"""
    global _scorer
    if _scorer is None:
        _scorer = FreePronunciationScorer()
    return _scorer


class ScoringUnavailable(RuntimeError):
    """The configured recognizer cannot perform an analysis."""


def score_pronunciation(audio, sr, target_word: str) -> List[Dict]:
    """Return experimental recognizer-derived scores, never randomized fallback scores."""
    scorer = get_scorer()
    if not POCKETSPHINX_AVAILABLE or scorer.decoder is None:
        raise ScoringUnavailable('Pronunciation recognizer is unavailable')
    return scorer.score_with_pocketsphinx(audio, sr, target_word) or []


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
        print("\nScoring remains unavailable until the recognizer is configured.")
    
    print(f"\nSupported words: {len(WORD_PHONEMES)}")
    print(f"Sample words: {list(WORD_PHONEMES.keys())[:5]}")
    print("\n" + "=" * 60)