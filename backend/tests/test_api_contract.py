import unittest
from unittest.mock import AsyncMock, patch
import httpx
from main import app

class IOSContractTests(unittest.IsolatedAsyncioTestCase):
    async def test_oversized_multipart_field_is_rejected_before_analysis(self):
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test') as client:
            with patch('main.analyze_speech', new=AsyncMock()) as analyze:
                response = await client.post('/api/analyze-pronunciation',
                    data={'target_word': 'x' * (1024 * 1024 + 1)},
                    files={'audio': ('sample.wav', b'test', 'audio/wav')})
                self.assertEqual(response.status_code, 400)
                analyze.assert_not_called()

    async def test_accepts_ios_multipart_and_legacy_query(self):
        result = {'overall_score': 80, 'phoneme_feedback': [{'phoneme': 'r', 'confidence': 0.8, 'needs_practice': False, 'tip': 'Practice'}], 'encouragement': 'Good practice'}
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test') as client:
            for suffix, data in [('', {'target_word': 'rain', 'language': 'en'}), ('?target_word=rain&language=en', {})]:
                with patch('main.analyze_speech', new=AsyncMock(return_value=result)) as analyze:
                    response = await client.post('/api/analyze-pronunciation' + suffix, data=data, files={'audio': ('sample.wav', b'test', 'audio/wav')})
                    self.assertEqual(response.status_code, 200, response.text)
                    self.assertEqual(analyze.call_args.args[1], 'rain')
                    self.assertEqual(response.json()['overall_score'], 0.8)
                    self.assertEqual(response.json()['transcribed_text'], '')
                    self.assertEqual(response.json()['phoneme_analysis'][0]['actualSound'], '')

    async def test_requires_nonempty_word(self):
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test') as client:
            response = await client.post('/api/analyze-pronunciation', data={'target_word': ' '}, files={'audio': ('sample.wav', b'test')})
            self.assertEqual(response.status_code, 422)

    async def test_exercises_reject_invalid_counts_and_difficulty(self):
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test') as client:
            for params in [{'count':-1},{'count':0},{'count':6},{'difficulty':'unexpected'}]:
                with self.subTest(params=params), patch('main.get_user_progress_summary') as summary:
                    response = await client.get('/api/exercises/adaptive',params={'user_id':'test',**params})
                    self.assertEqual(response.status_code,422)
                    summary.assert_not_called()

    async def test_exercise_difficulty_matches_requested_level(self):
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test') as client:
            for difficulty, level in [('easy',1),('medium',2),('hard',3)]:
                for sounds in [[],['r','s']]:
                    with self.subTest(difficulty=difficulty,sounds=sounds), patch('main.get_user_progress_summary',return_value={'still_practicing':sounds}):
                        response = await client.get('/api/exercises/adaptive',params={'user_id':'test','count':5,'difficulty':difficulty})
                        self.assertEqual(response.status_code,200)
                        self.assertEqual(len(response.json()),5)
                        self.assertTrue(all(row['difficulty']==level for row in response.json()))
            response = await client.get('/api/exercises/adaptive',params={'user_id':'test','count':1})
            self.assertEqual(len(response.json()),1)
