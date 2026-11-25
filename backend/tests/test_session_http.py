"""Exercise the real HTTP routes and database across server process restarts."""
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import time
import unittest

import httpx


@unittest.skipUnless(os.name == 'posix', 'Inherited listener requires POSIX')
class SessionHTTPTests(unittest.TestCase):
    def test_restart_and_retry_preserve_progress(self):
        backend = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as directory, socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            listener.listen()
            url = f'http://127.0.0.1:{listener.getsockname()[1]}'
            environment = {**os.environ, 'SPEECH_SESSION_DB': str(Path(directory) / 'sessions.sqlite3')}
            payload = {'user_id': 'alice', 'session_id': 'stable-attempt',
                       'timestamp': '2026-01-01T12:00:00Z', 'word': 'rain', 'language': 'en',
                       'pronunciation_result': {'overall_score': .95}, 'time_spent': 12, 'attempt_number': 1}
            before = None
            for restart in range(2):
                with tempfile.TemporaryFile() as log:
                    process = subprocess.Popen(
                        [sys.executable, '-m', 'uvicorn', 'main:app', '--fd', str(listener.fileno())],
                        cwd=backend, env=environment, pass_fds=(listener.fileno(),), stdout=log, stderr=log,
                    )
                    try:
                        with httpx.Client(base_url=url, timeout=2, trust_env=False) as client:
                            deadline = time.monotonic() + 30
                            while True:
                                try:
                                    if client.get('/health').status_code == 200:
                                        break
                                except httpx.HTTPError:
                                    pass
                                if process.poll() is not None or time.monotonic() >= deadline:
                                    log.seek(0)
                                    self.fail(log.read().decode(errors='replace'))
                                time.sleep(.05)
                            if restart:
                                self.assertEqual(client.get('/api/progress/alice').json(), before)
                            response = client.post('/api/sessions', json=payload)
                            self.assertEqual(response.status_code, 200, response.text)
                            self.assertEqual(response.json()['new_achievements'], [] if restart else ['First Practice!'])
                            progress = client.get('/api/progress/alice').json()
                            self.assertEqual(progress['total_sessions'], 1)
                            self.assertEqual(progress['total_coins'], 95)
                            self.assertEqual(client.get('/api/progress/bob').json()['total_sessions'], 0)
                            self.assertEqual(client.post('/api/sessions', json={**payload, 'word': 'changed'}).status_code, 409)
                            before = progress
                    finally:
                        process.terminate()
                        try:
                            process.wait(timeout=10)
                        except subprocess.TimeoutExpired:
                            process.kill()
                            process.wait(timeout=10)
