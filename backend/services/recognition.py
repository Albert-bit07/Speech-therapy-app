"""Offline recognition diagnostics, deliberately separate from assessment scores."""
import argparse
import json
import wave
from pathlib import Path

from pocketsphinx import Decoder, get_model_path


SAMPLE_RATE = 16000
FRAME_RATE = 100
MAX_SECONDS = 30


class RecognitionUnavailable(RuntimeError):
    """The native recognizer could not produce a complete diagnostic result."""


def _decode(decoder, pcm):
    decoder.start_utt()
    try:
        decoder.process_raw(pcm, no_search=False, full_utt=True)
    finally:
        decoder.end_utt()


def recognize_pcm(pcm: bytes, sample_rate: int = SAMPLE_RATE) -> dict:
    """Recognize bounded mono signed little-endian 16-bit PCM, then align it.

    Phone labels come from the recognized words' dictionary pronunciations.
    They are alignment hypotheses, not independently detected articulations.
    A fresh decoder keeps search and adaptation state isolated between calls.
    """
    if not isinstance(pcm, bytes) or not pcm or len(pcm) % 2:
        raise ValueError('Expected nonempty signed 16-bit PCM bytes')
    if sample_rate != SAMPLE_RATE or len(pcm) > SAMPLE_RATE * MAX_SECONDS * 2:
        raise ValueError('Expected at most 30 seconds of mono 16000 Hz audio')
    empty = {'transcript': '', 'words': []}
    # Digital silence is unambiguous. This is not a general speech/noise gate.
    if not any(pcm):
        return empty

    try:
        model = Path(get_model_path()) / 'en-us'
        decoder = Decoder(hmm=str(model / 'en-us'),
                          dict=str(model / 'cmudict-en-us.dict'),
                          lm=str(model / 'en-us.lm.bin'),
                          samprate=SAMPLE_RATE, frate=FRAME_RATE, loglevel='ERROR')
        _decode(decoder, pcm)
        hypothesis = decoder.hyp()
        transcript = hypothesis.hypstr.strip() if hypothesis else ''
        if not transcript:
            return empty

        # Capture the transcript before switching search modes. hyp() is not
        # valid for the native sub-word alignment search in PocketSphinx 5.1.1.
        decoder.set_alignment()
        _decode(decoder, pcm)
        alignment = decoder.get_alignment()
        if alignment is None:
            raise RecognitionUnavailable('No sub-word alignment available')
        words = []
        for word in alignment:
            if word.name in {'<s>', '</s>', '<sil>'}:
                continue
            phones = [{'phone': phone.name,
                       'start_seconds': phone.start / FRAME_RATE,
                       'end_seconds': (phone.start + phone.duration) / FRAME_RATE}
                      for phone in word if phone.duration > 0]
            if not phones:
                raise RecognitionUnavailable('Incomplete phone alignment')
            words.append({'word': word.name, 'phones': phones})
        if not words:
            raise RecognitionUnavailable('No aligned words available')
        return {'transcript': transcript, 'words': words}
    except RecognitionUnavailable:
        raise
    except Exception as exc:
        raise RecognitionUnavailable('Recognition or alignment failed') from exc


def read_wave(path: Path) -> bytes:
    with wave.open(str(path), 'rb') as audio:
        if (audio.getnchannels(), audio.getsampwidth(), audio.getframerate(),
                audio.getcomptype()) != (1, 2, SAMPLE_RATE, 'NONE'):
            raise ValueError('Expected uncompressed mono signed 16-bit 16000 Hz WAV')
        frames = audio.getnframes()
        if not 0 < frames <= SAMPLE_RATE * MAX_SECONDS:
            raise ValueError('Expected between one frame and 30 seconds of audio')
        pcm = audio.readframes(frames)
        if len(pcm) != frames * 2:
            raise ValueError('Truncated WAV data')
        return pcm


def main():
    parser = argparse.ArgumentParser(description='Experimental transcript and phone alignment; no assessment scores')
    parser.add_argument('wav', type=Path)
    args = parser.parse_args()
    try:
        result = recognize_pcm(read_wave(args.wav))
    except (ValueError, OSError, EOFError, wave.Error, RecognitionUnavailable) as exc:
        parser.exit(1, f'{exc}\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
