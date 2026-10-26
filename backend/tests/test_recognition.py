import json
import os
import random
import struct
from types import SimpleNamespace
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch
import wave

from services import recognition


FIXTURE = Path(__file__).parent / 'fixtures' / 'goforward.raw'


class RecognitionTests(unittest.TestCase):
    def test_real_fixture_through_cli(self):
        # Native failures must be reported as test failures, not kill discovery.
        with tempfile.TemporaryDirectory() as temporary:
            wav = Path(temporary) / 'speech.wav'
            with wave.open(str(wav), 'wb') as output:
                output.setparams((1, 2, 16000, 0, 'NONE', 'not compressed'))
                output.writeframes(FIXTURE.read_bytes())
            completed = subprocess.run([sys.executable, '-m', 'services.recognition', str(wav)],
                env={**os.environ, 'PYTHONPATH': str(Path(__file__).resolve().parents[1])},
                capture_output=True, text=True, timeout=30)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        result = json.loads(completed.stdout)
        self.assertEqual(result['transcript'], 'go forward ten meters')
        self.assertEqual([word['word'] for word in result['words']], ['go', 'forward', 'ten', 'meters'])
        self.assertEqual([p['phone'] for p in result['words'][0]['phones']], ['G', 'OW'])
        previous_end = 0
        for word in result['words']:
            self.assertEqual(set(word), {'word', 'phones'})
            for phone in word['phones']:
                self.assertEqual(set(phone), {'phone', 'start_seconds', 'end_seconds'})
                self.assertGreaterEqual(phone['start_seconds'], previous_end)
                self.assertGreater(phone['end_seconds'], phone['start_seconds'])
                self.assertLessEqual(phone['end_seconds'], len(FIXTURE.read_bytes()) / 32000)
                previous_end = phone['end_seconds']

    def test_digital_silence_never_initializes_decoder(self):
        with patch.object(recognition, 'Decoder') as decoder:
            self.assertEqual(recognition.recognize_pcm(bytes(32000)), {'transcript': '', 'words': []})
            decoder.assert_not_called()

    def test_invalid_input_never_initializes_decoder(self):
        with patch.object(recognition, 'Decoder') as decoder:
            for pcm, rate in [(b'', 16000), (b'\x00', 16000), (b'\x01\x00', 8000),
                              (bytes(960002), 16000), ('not bytes', 16000)]:
                with self.subTest(rate=rate, length=len(pcm)), self.assertRaises(ValueError):
                    recognition.recognize_pcm(pcm, rate)
            decoder.assert_not_called()

    def test_native_failure_closes_utterance_and_next_call_uses_new_decoder(self):
        failed = Mock()
        failed.process_raw.side_effect = RuntimeError('native error')
        recovered = Mock()
        recovered.hyp.return_value = None
        with patch.object(recognition, 'Decoder', side_effect=[failed, recovered]):
            with self.assertRaises(recognition.RecognitionUnavailable):
                recognition.recognize_pcm(b'\x01\x00')
            self.assertEqual(recognition.recognize_pcm(b'\x01\x00'), {'transcript': '', 'words': []})
        failed.end_utt.assert_called_once()
        failed.hyp.assert_not_called()
        recovered.set_alignment.assert_not_called()

    def test_alignment_failure_does_not_return_partial_results_or_read_hypothesis_again(self):
        decoder = Mock()
        decoder.hyp.return_value = Mock(hypstr='hello')
        decoder.process_raw.side_effect = [None, RuntimeError('alignment failed')]
        with patch.object(recognition, 'Decoder', return_value=decoder), self.assertRaises(recognition.RecognitionUnavailable):
            recognition.recognize_pcm(b'\x01\x00')
        self.assertEqual(decoder.end_utt.call_count, 2)
        decoder.hyp.assert_called_once()

    def test_wav_format_validation(self):
        with tempfile.TemporaryDirectory() as temporary:
            wav = Path(temporary) / 'invalid.wav'
            for channels, rate in [(2, 16000), (1, 8000)]:
                with wave.open(str(wav), 'wb') as output:
                    output.setparams((channels, 2, rate, 0, 'NONE', 'not compressed'))
                    output.writeframes(bytes(100))
                with self.assertRaises(ValueError):
                    recognition.read_wave(wav)

    def test_invalid_native_phone_spans_are_rejected_without_partial_output(self):
        class Word(list):
            name = 'hello'
        for start, duration, name in [(-1,5,'AH'), (5,5,'AH'), (90,20,'AH'),
                                      (10,0,'AH'), (10,-1,'AH'), (10,5,''), (10.5,5,'AH')]:
            decoder = Mock()
            decoder.hyp.return_value = Mock(hypstr='hello')
            decoder.get_alignment.return_value = [Word([
                SimpleNamespace(name='HH',start=0,duration=10),
                SimpleNamespace(name=name,start=start,duration=duration),
            ])]
            with self.subTest(start=start,duration=duration,name=name):
                with patch.object(recognition,'Decoder',return_value=decoder):
                    with self.assertRaises(recognition.RecognitionUnavailable):
                        recognition.recognize_pcm(b'\x01\x00' * 16000)

    def test_synthetic_non_speech_through_native_cli(self):
        rng = random.Random(20261026)
        cases = {
            'low_noise': [rng.randint(-100,100) for _ in range(16000)],
            'loud_noise': [rng.randint(-30000,30000) for _ in range(16000)],
            'constant': [1000] * 16000,
            'impulse': [30000] + [0] * 15999,
            'one_sample': [1],
        }
        # These fixed inputs are robustness fixtures, not a speech/noise classifier.
        with tempfile.TemporaryDirectory() as temporary:
            for name, samples in cases.items():
                with self.subTest(case=name):
                    wav = Path(temporary) / (name + '.wav')
                    with wave.open(str(wav),'wb') as output:
                        output.setparams((1,2,16000,0,'NONE','not compressed'))
                        output.writeframes(struct.pack('<' + 'h' * len(samples),*samples))
                    completed = subprocess.run([sys.executable,'-m','services.recognition',str(wav)],
                        env={**os.environ,'PYTHONPATH':str(Path(__file__).resolve().parents[1])},
                        capture_output=True,text=True,timeout=30)
                    self.assertEqual(completed.returncode,0,completed.stderr)
                    self.assertEqual(json.loads(completed.stdout),{'transcript':'','words':[]})
