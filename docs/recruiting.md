> Historical review: this page records the pre-repair baseline. Current decoder, request-contract fixes and validation are documented in the [README](../README.md).

# Recruiting notes — ChatterQuest / SpeakBright

## One sentence / suggested repository description

Collaborative SwiftUI speech-practice game prototype with FastAPI audio-analysis APIs and explicitly documented mock-scoring boundaries.

## 30-second explanation

I contributed backend services to a collaborative speech-practice game. The Python side defines audio-analysis, session, exercise and progress APIs, with PocketSphinx integration and rule-based feedback. The SwiftUI game currently uses mock analysis. My strongest engineering discussion is aligning the client/server contract, separating mock output from real inference and managing session state. We have not established clinical accuracy or a fully integrated working assessment pipeline.

## Recruiter email paragraph

In ChatterQuest/SpeakBright, I contributed Python backend implementation for a collaborative mobile practice-game prototype. The project connects API schemas, audio-processing code, heuristic scoring and feedback generation, while documenting the current mock UI path and integration gaps. It gives me concrete experience discussing API contracts and the distinction between a prototype response and validated inference.

## Resume bullets

- Developed FastAPI backend routes and Pydantic schemas for pronunciation-analysis requests, practice sessions, progress summaries and exercise responses in a collaborative SwiftUI project.
- Added an audio-analysis service structure combining PocketSphinx integration, heuristic/mock scoring fallbacks and rule-based feedback; documented client/server contract and state-management limitations.

Use backend-focused wording; do not claim sole ownership of the SwiftUI game, clinical results, model training or a working end-to-end deployment.

## Engineering manager explanation

The useful architecture is a typed API adapter over audio-processing, scoring and feedback services, separate from game state. The checked implementation has mismatched client inputs, mock UI analysis and non-durable stores. The next credible milestone is a deterministic synthetic-audio contract test and visible mock provenance, followed by real scoring evaluation. Authorship history supports Albert's backend contributions; it does not establish every teammate's precise scope.

## Skills and talking points

Python, FastAPI, Pydantic, multipart contracts, audio preprocessing, heuristic scoring, mock/inference provenance, session state, privacy boundaries and collaboration. Best framing: backend/full-stack prototype. Do not market this as clinically validated ML or production ML infrastructure.
