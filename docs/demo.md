> Historical review: this page records the pre-repair baseline. Current decoder, request-contract fixes and validation are documented in the [README](../README.md).

# 90-second demonstration plan

The [original author-provided recording](https://youtu.be/bkb0GQkSVr0) is linked for continuity, not verified here. A new recording has not been produced.

Use a simulator and synthetic or adult non-sensitive audio. Prepare Xcode and the [backend setup](../README.md#setup) before recording. Do not expose the backend publicly.

- **0–20 s:** show the practice/game UI after a successful local build. Explain the engagement problem and shared project ownership.
- **20–45 s:** perform a game practice round if it runs. Clearly say that GameView currently uses mock analysis, so a score is a UI demonstration rather than an assessed recording.
- **45–65 s:** show the backend architecture and API definitions in `/docs` if the backend starts. Do not imply the running UI called those routes.
- **65–90 s:** show the explicit 503 response when the recognizer is unavailable. Explain that the multipart contract is tested, while real scoring and Swift integration remain unfinished.

For an independent backend request after resolving the documented blockers, FastAPI's current contract requires query parameters:

```bash
curl --fail -F 'audio=@synthetic.wav;type=audio/wav' \
  'http://127.0.0.1:8000/api/analyze-pronunciation?target_word=rainbow&language=en'
```

This is an **unexecuted diagnostic command**, not expected successful output. Use a known generated WAV file and inspect the result/error before recording. Do not narrate game mock scores as measured recognition accuracy. Stop the local processes you started; inspect and remove only your generated recording files and disposable environment.
