import concurrent.futures
from datetime import datetime, timezone
import multiprocessing
from pathlib import Path
import sqlite3
import tempfile
import unittest

from services.session_store import SessionConflict, SessionStore


def record(user='alice', score=.95):
    return {'user_id': user, 'timestamp': datetime(2026, 1, 1, tzinfo=timezone.utc),
            'word': 'private-word', 'result': {'overall_score': score, 'transcribed_text': 'private-transcript'},
            'time_spent': 12.0, 'language': 'en', 'attempt_number': 1}


def save_in_process(arguments):
    path, identifier = arguments
    return SessionStore(path).save(identifier, record())


class SessionStoreTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / 'sessions.sqlite3'
        self.store = SessionStore(self.path)

    def test_restart_replay_conflict_and_user_isolation(self):
        self.assertEqual(self.store.save('one', record()), (True, 1))
        restarted = SessionStore(self.path)
        self.assertEqual(restarted.save('one', record()), (False, 1))
        with self.assertRaises(SessionConflict):
            restarted.save('one', record(score=.5))
        self.assertEqual(restarted.save('one', record(user='bob')), (True, 1))
        self.assertEqual(restarted.for_user('alice')[0]['result']['overall_score'], .95)
        self.assertEqual(len(restarted.for_user('bob')), 1)
        self.assertEqual(restarted.for_user('unknown'), [])
        contents = self.path.read_bytes()
        self.assertNotIn(b'private-word', contents)
        self.assertNotIn(b'private-transcript', contents)

    def test_processes_serialize_duplicate_credit_and_counts(self):
        # Fresh spawned interpreters also verify recovery without shared Python state.
        context = multiprocessing.get_context('spawn')
        with concurrent.futures.ProcessPoolExecutor(max_workers=4, mp_context=context) as workers:
            results = list(workers.map(save_in_process, [(self.path, 'same')] * 8))
            self.assertEqual(sum(inserted for inserted, _ in results), 1)
            self.assertTrue(all(count == 1 for _, count in results))
            results = list(workers.map(save_in_process, [(self.path, str(i)) for i in range(12)]))
        self.assertTrue(all(inserted for inserted, _ in results))
        self.assertEqual(sorted(count for _, count in results), list(range(2, 14)))
        self.assertEqual(len(self.store.for_user('alice')), 13)

    def test_failed_transaction_leaves_retry_available(self):
        self.store.for_user('alice')
        with self.store.connection() as connection:
            connection.execute("""CREATE TRIGGER fail_insert AFTER INSERT ON sessions
                                  BEGIN SELECT RAISE(ABORT, 'injected failure'); END""")
        with self.assertRaises(sqlite3.IntegrityError):
            self.store.save('one', record())
        self.assertEqual(self.store.for_user('alice'), [])
        with self.store.connection() as connection:
            connection.execute('DROP TRIGGER fail_insert')
        self.assertEqual(self.store.save('one', record()), (True, 1))

    def test_rejects_nonfinite_and_oversized_content_without_saving(self):
        invalid = record()
        invalid['result']['other'] = float('nan')
        with self.assertRaises(ValueError):
            self.store.save('one', invalid)
        oversized = record()
        oversized['word'] = 'x' * 65536
        with self.assertRaises(ValueError):
            self.store.save('one', oversized)
        self.assertEqual(self.store.for_user('alice'), [])
