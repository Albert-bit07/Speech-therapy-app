import io
import unittest
from unittest.mock import Mock, patch
import numpy as np
import soundfile as sf
from fastapi import UploadFile, HTTPException
from services import pronunciation_scoring as scoring
from services.speech_analysis import analyze_speech, user_progress_db

class ScoringAvailabilityTests(unittest.IsolatedAsyncioTestCase):
    async def test_word_segments_never_create_progress(self):
        user_progress_db.clear()
        with patch.object(scoring, 'POCKETSPHINX_AVAILABLE', False):
            scorer = scoring.FreePronunciationScorer()
        scorer.decoder = Mock()
        scorer.decoder.hyp.return_value = Mock(hypstr='rain')
        scorer.decoder.seg.return_value = [Mock(word='rain', prob=0.9)]
        buffer = io.BytesIO()
        sf.write(buffer, np.ones(1600) * 0.1, 16000, format='WAV')
        buffer.seek(0)
        upload = UploadFile(file=buffer, filename='sample.wav')
        with patch.object(scoring, 'POCKETSPHINX_AVAILABLE', True), \
             patch.object(scoring, 'get_scorer', return_value=scorer):
            with self.assertRaises(HTTPException) as failure:
                await analyze_speech(upload, 'rain', user_id='word-segments')
        self.assertEqual(failure.exception.status_code, 503)
        self.assertEqual(user_progress_db, {})
        self.assertTrue(buffer.closed)

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


class DecoderAudioTests(unittest.TestCase):
    def test_word_search_output_is_not_phoneme_evidence(self):
        for words in ([], ['rain'], ['R'], ['R', 'EY1', 'N']):
            with self.subTest(words=words):
                scorer = self.make_scorer()
                scorer.decoder.hyp.return_value = Mock(hypstr='rain')
                scorer.decoder.seg.return_value = [
                    Mock(word=word, prob=0.9) for word in words]
                with self.assertRaises(scoring.ScoringUnavailable):
                    scorer.score_with_pocketsphinx(np.ones(1600) * .1, 16000, 'rain')
                scorer.decoder.end_utt.assert_called_once()

    def make_scorer(self):
        with patch.object(scoring, 'POCKETSPHINX_AVAILABLE', False):
            scorer = scoring.FreePronunciationScorer()
        scorer.decoder = Mock()
        scorer.decoder.hyp.return_value = None
        return scorer

    def test_passes_saturated_pcm_without_a_container_header(self):
        scorer = self.make_scorer()
        samples = np.array([-2.0, -1.0, -.5, 0, .5, 1.0, 2.0])
        self.assertIsNone(scorer.score_with_pocketsphinx(samples, 16000, 'rain'))
        payload = scorer.decoder.process_raw.call_args.args[0]
        self.assertEqual(len(payload), len(samples) * 2)
        self.assertEqual(np.frombuffer(payload, dtype='<i2').tolist(),
                         [-32768, -32768, -16384, 0, 16384, 32767, 32767])
        self.assertEqual(scorer.decoder.method_calls, [
            unittest.mock.call.start_utt(),
            unittest.mock.call.process_raw(payload, no_search=False, full_utt=True),
            unittest.mock.call.end_utt(), unittest.mock.call.hyp()])

    def test_rejects_invalid_audio_before_opening_an_utterance(self):
        scorer = self.make_scorer()
        for samples, rate in [(np.zeros(10), 8000), (np.zeros((2, 2)), 16000),
                              (np.array([]), 16000), (np.array([np.nan]), 16000),
                              (np.array([np.inf]), 16000)]:
            with self.subTest(samples=samples, rate=rate), self.assertRaises(ValueError):
                scorer.score_with_pocketsphinx(samples, rate, 'rain')
        scorer.decoder.start_utt.assert_not_called()

    def test_native_failure_closes_utterance_and_reports_unavailable(self):
        scorer = self.make_scorer()
        scorer.decoder.process_raw.side_effect = RuntimeError('native failure')
        with self.assertRaises(scoring.ScoringUnavailable):
            scorer.score_with_pocketsphinx(np.zeros(10), 16000, 'rain')
        scorer.decoder.end_utt.assert_called_once()
        scorer.decoder.hyp.assert_not_called()
        scorer.decoder.process_raw.side_effect = None
        self.assertIsNone(scorer.score_with_pocketsphinx(np.zeros(10), 16000, 'rain'))

    def test_parallel_requests_do_not_overlap_decoder_state(self):
        from concurrent.futures import ThreadPoolExecutor
        import time
        scorer = self.make_scorer()
        active = False
        def start():
            nonlocal active
            if active:
                raise AssertionError('Overlapping decoder utterances')
            active = True
            time.sleep(.005)
        def hypothesis():
            nonlocal active
            self.assertTrue(active)
            active = False
            return None
        scorer.decoder.start_utt.side_effect = start
        scorer.decoder.hyp.side_effect = hypothesis
        with ThreadPoolExecutor(max_workers=4) as pool:
            results = list(pool.map(lambda _: scorer.score_with_pocketsphinx(
                np.zeros(10), 16000, 'rain'), range(12)))
        self.assertEqual(results, [None] * 12)
