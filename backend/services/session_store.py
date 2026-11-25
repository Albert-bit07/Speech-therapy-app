"""Durable, duplicate-safe iOS progress without retaining speech transcripts."""
from contextlib import contextmanager
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import sqlite3


class SessionConflict(ValueError):
    pass


class SessionStore:
    def __init__(self, path):
        self.path = Path(path)

    @contextmanager
    def connection(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(self.path, timeout=5)
        try:
            connection.execute("""
                CREATE TABLE IF NOT EXISTS sessions (
                    user_id TEXT NOT NULL,
                    session_id TEXT NOT NULL,
                    fingerprint TEXT NOT NULL,
                    timestamp TEXT NOT NULL,
                    score REAL NOT NULL CHECK(score >= 0 AND score <= 1),
                    PRIMARY KEY (user_id, session_id)
                )
            """)
            with connection:
                yield connection
        finally:
            connection.close()

    def save(self, session_id, record):
        """Return (inserted, user_count) from one serialized transaction."""
        canonical = {**record, 'timestamp': record['timestamp'].isoformat()}
        encoded = json.dumps(canonical, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()
        if len(encoded) > 65536:
            raise ValueError('Session content exceeds 64 KiB')
        fingerprint = hashlib.sha256(encoded).hexdigest()
        with self.connection() as connection:
            # Compare and insert under the same lock across worker processes.
            connection.execute('BEGIN IMMEDIATE')
            previous = connection.execute(
                'SELECT fingerprint FROM sessions WHERE user_id = ? AND session_id = ?',
                (record['user_id'], session_id),
            ).fetchone()
            if previous is not None and previous[0] != fingerprint:
                raise SessionConflict('Session ID already used for different content')
            if previous is None:
                connection.execute('INSERT INTO sessions VALUES (?, ?, ?, ?, ?)', (
                    record['user_id'], session_id, fingerprint,
                    canonical['timestamp'], record['result']['overall_score'],
                ))
            count = connection.execute(
                'SELECT COUNT(*) FROM sessions WHERE user_id = ?', (record['user_id'],)
            ).fetchone()[0]
            return previous is None, count

    def for_user(self, user_id):
        with self.connection() as connection:
            rows = connection.execute(
                'SELECT timestamp, score FROM sessions WHERE user_id = ? ORDER BY timestamp, session_id',
                (user_id,),
            ).fetchall()
        return [{'timestamp': datetime.fromisoformat(timestamp), 'result': {'overall_score': score}}
                for timestamp, score in rows]


def get_session_store():
    default = Path(__file__).resolve().parents[1] / 'data' / 'sessions.sqlite3'
    return SessionStore(os.environ.get('SPEECH_SESSION_DB', default))
