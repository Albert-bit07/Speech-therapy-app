import io
import unittest
from unittest.mock import Mock, patch
import numpy as np
import soundfile as sf
from fastapi import UploadFile, HTTPException
from services import pronunciation_scoring as scoring
from services.speech_analysis import analyze_speech, user_progress_db

class ScoringAvailabilityTests(unittest.IsolatedAsyncioTestCase):
    async def test_missing_recognizer_never_fabricates_scores_or_progress(self):
        user_progress_db.clear()
        buffer=io.BytesIO()
        sf.write(buffer,np.zeros(1600),16000,format='WAV');buffer.seek(0)
        upload=UploadFile(file=buffer,filename='sample.wav')
        with patch.object(scoring,'POCKETSPHINX_AVAILABLE',False), patch.object(scoring,'get_scorer',return_value=Mock(decoder=None)):
            with self.assertRaises(HTTPException) as failure:
                await analyze_speech(upload,'rain',user_id='unavailable')
        self.assertEqual(failure.exception.status_code,503)
        self.assertEqual(user_progress_db,{})
        self.assertTrue(buffer.closed)

    def test_no_recognition_returns_no_scores(self):
        recognizer=Mock(decoder=object())
        recognizer.score_with_pocketsphinx.return_value=None
        with patch.object(scoring,'POCKETSPHINX_AVAILABLE',True), patch.object(scoring,'get_scorer',return_value=recognizer):
            self.assertEqual(scoring.score_pronunciation(np.zeros(10),16000,'rain'),[])

    def test_confidence_heuristic_is_deterministic(self):
        scorer=scoring.FreePronunciationScorer.__new__(scoring.FreePronunciationScorer)
        with patch('numpy.random.uniform',side_effect=AssertionError('Random confidence is forbidden')):
            scores=[scorer.calculate_phoneme_confidence('R','R') for _ in range(5)]
        self.assertEqual(scores,[.95]*5)
