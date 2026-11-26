# Demonstrating the implemented workflows

Use a local backend and macOS/Xcode. Follow the [setup instructions](../README.md#setup); do not expose this unauthenticated prototype publicly. The original [author recording](https://youtu.be/bkb0GQkSVr0) is historical and has not been verified against the current implementation. No new recording or screenshot is claimed here.

1. Open onboarding and the game. Show the English exercise catalog and Hear Word control. Toggle word hints in Settings. Actual audible playback requires a device/simulator with audio and has not been validated by headless builds.
2. Explain that the pronunciation endpoint currently returns an unavailable error: there is no implemented, validated pronunciation assessment. Do not narrate a fabricated scored battle or treat a recognition transcript as an assessment.
3. Demonstrate persistence using the automated HTTP harness described in the README: actual Swift client, local outbox, FastAPI and SQLite, with a synthetic score, dropped acknowledgments and both-process restart. The test checks that replay does not duplicate progress.
4. Open the Parent screen. A fresh installation should show empty saved progress; it must not show sample improvement statistics. Add a local note, relaunch, and verify its content and deletion. These are manual verification steps, not a claim that interactive testing has already been performed.
5. Show the CI jobs and explain their limits: backend/API contracts, native recognition fixtures, Debug/Release compilation and persistence regressions are distinct from UI, microphone and model-quality evaluation.

The diagnostic CLI can be demonstrated separately with permitted English audio:

```bash
PYTHONPATH=backend python -m services.recognition recording.wav
```

Use uncompressed mono signed 16-bit WAV at 16 kHz, at most 30 seconds. The CLI emits recognition/alignment data, no pronunciation score. Inspect actual output before recording a demo; do not assume a transcript is accurate. Stop local processes and remove only your generated test recordings afterward.
