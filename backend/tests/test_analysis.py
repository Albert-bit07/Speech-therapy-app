import io
import unittest
from unittest.mock import patch
import numpy as np
import soundfile as sf
from fastapi import UploadFile
from services.speech_analysis import analyze_speech, user_progress_db

class AnalysisTests(unittest.IsolatedAsyncioTestCase):
    async def test_wav_and_repeat_attempt(self):
        user_progress_db.clear()
        scores = [{'phoneme': 'r', 'confidence': 0.5, 'expected': 'r', 'detected': 'r'}]
        def audio():
            stream = io.BytesIO()
            sf.write(stream, np.zeros(1600), 16000, format='WAV')
            stream.seek(0)
            return UploadFile(file=stream, filename='sample.wav')
        with patch('services.speech_analysis.score_pronunciation', return_value=scores):
            first = await analyze_speech(audio(), 'rain', user_id='test')
            self.assertEqual(first['overall_score'], 50)
            scores[0]['confidence'] = 0.8
            second = await analyze_speech(audio(), 'rain', user_id='test')
            self.assertEqual(second['progress'].phonemes_improved, ['r'])
            self.assertEqual(len(user_progress_db['test']), 2)

    async def test_invalid_audio_has_client_error(self):
        from fastapi import HTTPException
        with self.assertRaises(HTTPException) as error:
            await analyze_speech(UploadFile(file=io.BytesIO(b'not audio')), 'rain')
        self.assertEqual(error.exception.status_code, 400)
