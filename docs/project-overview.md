# Engineering overview

## Pipeline and design decisions

The backend [analyze_speech](../backend/services/speech_analysis.py) reads uploaded bytes, attempts librosa processing at 16 kHz, invokes a pronunciation scorer, generates rule-based feedback/exercises, and optionally appends abstract progress objects in memory. The [scorer](../backend/services/pronunciation_scoring.py) attempts PocketSphinx model loading and recognizes speech, then compares expected sounds with decoder segments. Its confidence is heuristic and includes random variation. Failure/no result can switch to mock scoring. This is neither a validated phoneme alignment system nor model training.

The iOS adapter rescales scores to 0–1 and sets `transcribed_text` to the supplied target word. It is **not** independent transcription evidence. A `language` parameter exists but does not establish multilingual scoring. Dictionaries, preset words and hand-authored feedback define the practical content scope.

## Hard integration problems still open

- GameView uses MockAPIService for analysis and exercises. The separate real client sends multipart word/language fields while FastAPI declares query parameters; requests need contract alignment.
- Audio bytes are passed through `buf_to_float` and then into `librosa.load`. Encoded WAV/recording bytes need a verified decoder path; current compatibility has not been established.
- The scorer marks mock/PocketSphinx provenance, but the feedback mapper and iOS adapter do not preserve those flags in the public result. A caller cannot reliably distinguish fallback scoring from recognition using that result.
- Progress history stores Pydantic objects, while a comparison path uses dictionary `.get`. Repeat analysis with progress enabled needs regression coverage.
- Separate in-memory session/progress stores are not reconciled. Streaks return constants and weekly data is generated from placeholders. Achievement lookup uses user ID against a session-ID-keyed dictionary.

These are source-inspection findings, not observed runtime traces. No fixes to application behavior are included here.

## Security and privacy scope

There is no login, authorization, per-user access enforcement or durable retention policy. CORS permits all origins. The API reads entire uploads, with no demonstrated size/type boundary. The frontend logs requests/responses and records to a local file; the backend's local-variable deletion and compliance-themed log message do not guarantee erasure from framework buffers, temporary upload storage or device files. Use no identifiable child recordings for a public demonstration. A tracked `.env` requires a separate owner review; this documentation does not reproduce values or assert that they are live credentials.

## Validation — 2026-10-20

Inspected routes, schemas, scoring/audio services, Swift API and game path, build project and git history. Seven Python files parsed successfully via AST. FastAPI, librosa and PocketSphinx were unavailable; pinned dependencies were not installed and no runtime request was made. Linux has no `xcodebuild`; Swift compilation and simulator behavior remain unverified. No AGENTS.md, tests or CI workflow was found. No accuracy, clinical efficacy, persistent recovery or privacy guarantee was verified.

## Next improvements

Define a single multipart/query API contract, expose mock provenance in responses and UI, test decoding with synthetic WAV files, preserve scoring provenance through the response, reconcile session/progress storage and replace placeholders. Then add access control, upload limits and a documented retention model. Any future scoring evaluation needs consented, appropriately licensed audio and clear metrics; no evaluation is claimed by the current code.
