import unittest
from datetime import datetime, timedelta, timezone
import httpx
from main import app, sessions_db, calculate_streak, calculate_longest_streak, generate_weekly_progress

class ProgressTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        sessions_db.clear()
        self.client = httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test')
    async def asyncTearDown(self):
        await self.client.aclose()
        sessions_db.clear()
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
        self.assertEqual(len(sessions_db),0)
