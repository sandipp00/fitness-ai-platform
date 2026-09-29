# Personalization layer

## Historical trends

`GET /api/analytics/trends?days=28` aggregates recorded activity and sleep.
It returns:
- Daily series
- Average steps
- Average active minutes
- Average sleep
- Recent 7-day vs previous 7-day deltas

The comparison is descriptive, not predictive.

## Adaptive workout plan

`GET /api/analytics/workout-plan` uses:
- User goal
- Average activity
- Average sleep
- Latest recovery score

It selects a conservative weekly structure:
- Recovery
- Foundation
- Progressive

The plan is not a medical prescription. Users should modify or stop activity
for pain, dizziness, unusual shortness of breath, or other concerning symptoms.

## Vector retrieval

The resource layer now has an embedding-backed retrieval boundary using
`sentence-transformers` and cosine similarity. It lazily loads
`all-MiniLM-L6-v2`.

If the embedding dependency/model is unavailable, it automatically falls back
to deterministic keyword retrieval so local development still works.

For production:
- persist embeddings in pgvector/Qdrant/etc.
- version documents
- store publication/review dates
- re-index changed guidance
- preserve source URLs
- add evaluation sets for retrieval quality
