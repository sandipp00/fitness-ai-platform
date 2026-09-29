# AI Coach architecture

```text
Flutter Coach Screen
        |
        | authenticated question
        v
POST /api/ai/chat
        |
        +--> authenticated user context
        |       - goal
        |       - steps
        |       - active minutes
        |       - sleep
        |       - activity/sleep/recovery scores
        |
        +--> trusted resource retrieval
        |       - CDC
        |       - WHO
        |
        +--> optional OpenAI Responses API
        |
        v
Grounded answer + sources
```

## Configuration

Set these only on the backend:

```env
OPENAI_API_KEY=...
OPENAI_MODEL=gpt-5.6-luna
```

If `OPENAI_API_KEY` is empty, the endpoint remains functional using a
deterministic grounded fallback. This makes local development possible without
an API account.

## Why this design

The model does not receive an unrestricted request to invent fitness advice.
The backend constructs a context from the authenticated user's latest metrics
and retrieves trusted public-health guidance before generation.

The initial corpus uses CDC adult physical-activity guidance and WHO physical
activity guidance. CDC currently describes at least 150 minutes of moderate
activity or 75 minutes of vigorous activity weekly, plus muscle strengthening
on at least 2 days. WHO similarly recommends 150–300 minutes of moderate or
75–150 minutes of vigorous activity and strength work on 2+ days. citeturn0search0turn0search27

## Production expansion

For a production RAG system:
1. Store versioned resource documents.
2. Add chunking and embeddings.
3. Use a vector database.
4. Track document publication/review dates.
5. Re-index resources when guidance changes.
6. Return source citations to the client.
7. Add structured safety classification before generation.
8. Add audit logging without storing unnecessary raw health data.

The OpenAI API key must remain server-side. OpenAI's current platform exposes model access through the Responses API and client SDKs. citeturn1search0
