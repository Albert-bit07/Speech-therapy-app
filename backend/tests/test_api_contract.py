import unittest
from unittest.mock import AsyncMock, patch
import httpx
from main import app

class IOSContractTests(unittest.IsolatedAsyncioTestCase):
    async def test_accepts_ios_multipart_and_legacy_query(self):
        result = {'overall_score': 80, 'phoneme_feedback': [{'phoneme': 'r', 'confidence': 0.8, 'needs_practice': False, 'tip': 'Practice'}], 'encouragement': 'Good practice'}
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test') as client:
            for suffix, data in [('', {'target_word': 'rain', 'language': 'en'}), ('?target_word=rain&language=en', {})]:
                with patch('main.analyze_speech', new=AsyncMock(return_value=result)) as analyze:
                    response = await client.post('/api/analyze-pronunciation' + suffix, data=data, files={'audio': ('sample.wav', b'test', 'audio/wav')})
                    self.assertEqual(response.status_code, 200, response.text)
                    self.assertEqual(analyze.call_args.args[1], 'rain')
                    self.assertEqual(response.json()['overall_score'], 0.8)

    async def test_requires_nonempty_word(self):
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test') as client:
            response = await client.post('/api/analyze-pronunciation', data={'target_word': ' '}, files={'audio': ('sample.wav', b'test')})
            self.assertEqual(response.status_code, 422)
