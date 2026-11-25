import unittest
import tempfile
from pathlib import Path
from unittest.mock import patch
from services.session_store import SessionStore
from datetime import datetime, timedelta, timezone
import httpx
from main import app, calculate_streak, calculate_longest_streak, generate_weekly_progress

class ProgressTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.store = SessionStore(Path(self.directory.name) / 'sessions.sqlite3')
        self.store_patch = patch('main.get_session_store', return_value=self.store)
        self.store_patch.start()
        self.client = httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test')
    async def asyncTearDown(self):
        await self.client.aclose()
        self.store_patch.stop()
        self.directory.cleanup()
    def payload(self, identifier='one', user='alice', score=.95, timestamp=None):
        return {'user_id':user,'session_id':identifier,'timestamp':(timestamp or datetime.now(timezone.utc)).isoformat(),
                'word':'rain','language':'en','pronunciation_result':{'overall_score':score},'time_spent':12,'attempt_number':1}

    async def test_empty_history_has_no_invented_progress(self):
        response = await self.client.get('/api/progress/new-user')
        self.assertEqual(response.status_code,200)
        value = response.json()
        for field in ['total_sessions','total_stars','total_coins','current_streak','longest_streak','average_accuracy']:
            self.assertEqual(value[field],0)
        self.assertTrue(all(day['sessions_completed']==0 and day['average_score']==0 for day in value['weekly_progress']))

    async def test_saved_sessions_drive_totals_without_duplicate_credit(self):
        payload = self.payload()
        first = await self.client.post('/api/sessions',json=payload)
        self.assertEqual(first.status_code,200,first.text)
        self.assertEqual(first.json()['new_achievements'],['First Practice!'])
        again = await self.client.post('/api/sessions',json=payload)
        self.assertEqual(again.status_code,200)
        self.assertEqual(again.json()['session_id'],'one')
        self.assertEqual(again.json()['new_achievements'],[])
        self.assertEqual((await self.client.post('/api/sessions',json={**payload,'word':'changed'})).status_code,409)
        await self.client.post('/api/sessions',json=self.payload('two',score=.5))
        await self.client.post('/api/sessions',json=self.payload(user='bob'))
        value = (await self.client.get('/api/progress/alice')).json()
        self.assertEqual(value['total_sessions'],2)
        self.assertEqual(value['total_stars'],4)
        self.assertEqual(value['total_coins'],145)
        self.assertAlmostEqual(value['average_accuracy'],.725)
        self.assertEqual(value['current_streak'],1)
        self.assertEqual(value['weekly_progress'][-1]['sessions_completed'],2)
        self.assertEqual((await self.client.get('/api/progress/bob')).json()['total_sessions'],1)

    async def test_streaks_use_unique_utc_dates_and_real_gaps(self):
        today = datetime(2026,1,10,tzinfo=timezone.utc)
        for index, offset in enumerate([0,0,1,2,4,5,6,7]):
            response=await self.client.post('/api/sessions',json=self.payload(str(index),timestamp=today-timedelta(days=offset)))
            self.assertEqual(response.status_code,200)
        self.assertEqual(calculate_streak('alice',today.date()),3)
        self.assertEqual(calculate_streak('alice',(today+timedelta(days=1)).date()),3)
        self.assertEqual(calculate_streak('alice',(today+timedelta(days=2)).date()),0)
        self.assertEqual(calculate_longest_streak('alice'),4)
        weekly=generate_weekly_progress('alice',today.date())
        self.assertEqual([day['sessions_completed'] for day in weekly],[1,1,1,0,1,1,2])

    async def test_rejects_invalid_scores_before_saving(self):
        for score in [None, '0.9', True, -1, 1.1]:
            response=await self.client.post('/api/sessions',json=self.payload(score=score))
            self.assertEqual(response.status_code,422)
        future=self.payload(timestamp=datetime.now(timezone.utc)+timedelta(days=1))
        self.assertEqual((await self.client.post('/api/sessions',json=future)).status_code,422)
        self.assertEqual(len(self.store.for_user('alice')),0)

    async def test_restart_preserves_api_progress_and_retry_semantics(self):
        payload = self.payload()
        self.assertEqual((await self.client.post('/api/sessions', json=payload)).status_code, 200)
        before = (await self.client.get('/api/progress/alice')).json()
        with patch('main.get_session_store', return_value=SessionStore(self.store.path)) as provider:
            after = await self.client.get('/api/progress/alice')
            self.assertEqual(after.json(), before)
            provider.assert_called_once()  # Aggregates share a single read snapshot.
            retry = await self.client.post('/api/sessions', json=payload)
            self.assertEqual(retry.status_code, 200)
            self.assertEqual(retry.json()['new_achievements'], [])
            conflict = await self.client.post('/api/sessions', json={**payload, 'word': 'changed'})
            self.assertEqual(conflict.status_code, 409)

    async def test_storage_failure_returns_retryable_error_without_credit(self):
        import sqlite3
        with patch.object(self.store, 'save', side_effect=sqlite3.OperationalError('disk error')):
            response = await self.client.post('/api/sessions', json=self.payload())
            self.assertEqual(response.status_code, 503)
            self.assertNotIn('disk error', response.text)
        self.assertEqual(self.store.for_user('alice'), [])
        with patch.object(self.store, 'for_user', side_effect=sqlite3.OperationalError('disk error')):
            self.assertEqual((await self.client.get('/api/progress/alice')).status_code, 503)

    async def test_content_limits_do_not_create_records(self):
        payload = self.payload()
        for invalid in [dict(payload, user_id='x' * 129), dict(payload, session_id='x' * 129),
                        dict(payload, word='x' * 65536)]:
            response = await self.client.post('/api/sessions', json=invalid)
            self.assertEqual(response.status_code, 422)
        self.assertEqual(self.store.for_user('alice'), [])
