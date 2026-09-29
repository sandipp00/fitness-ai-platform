from dataclasses import asdict
from openai import OpenAI
from ..config import settings
from .vector_store import vector_store


SYSTEM_PROMPT = """You are Fitness AI Coach, a wellness assistant.
Use the supplied user metrics and retrieved trusted health guidance.
Give practical, conservative fitness guidance.

Rules:
- Do not diagnose diseases.
- Do not prescribe medicines or treatment.
- Do not tell a user to ignore medical advice.
- Do not infer medical conditions from fitness metrics.
- Clearly distinguish user-specific observations from general guidelines.
- If the question suggests an emergency or serious medical problem, tell the
  user to seek appropriate urgent professional care rather than coaching it.
- Never claim certainty that the data does not support.
- Prefer small, sustainable changes.
- Cite retrieved sources by publisher/title in a short "Sources" section.
"""


def _fallback(question: str, context: dict, sources: list) -> str:
    steps = context.get("steps", 0)
    sleep = context.get("sleep_hours", 0)
    active = context.get("active_minutes", 0)

    lines = ["Based on your latest recorded data:"]
    lines.append(f"- Steps: {steps}")
    lines.append(f"- Active minutes: {active}")
    lines.append(f"- Sleep: {sleep:.1f} hours")

    if steps < 5000:
        lines.append(
            "A reasonable next step is to add a short, comfortable walk "
            "or another low-intensity movement session."
        )
    if sleep and sleep < 7:
        lines.append(
            "Your recorded sleep is below 7 hours, so prioritizing a "
            "consistent sleep opportunity may be useful."
        )
    if not any([steps < 5000, sleep and sleep < 7]):
        lines.append(
            "Your current signals do not point to an obvious need for a "
            "large change from a single day. Consistency is more useful "
            "than reacting to one measurement."
        )

    lines.append("")
    lines.append("General guidance:")
    for source in sources:
        lines.append(f"- {source.title} ({source.publisher})")

    return "\n".join(lines)


def answer(question: str, context: dict) -> dict:
    sources = vector_store.search(question)

    if not settings.openai_api_key:
        return {
            "answer": _fallback(question, context, sources),
            "mode": "grounded_fallback",
            "sources": [asdict(x) for x in sources],
        }

    source_text = "\n\n".join(
        f"[{s.publisher}] {s.title}\n{s.content}\nSource: {s.source_url}"
        for s in sources
    )

    user_prompt = f"""User question:
{question}

Latest fitness context:
{context}

Trusted guidance:
{source_text}

Answer the question directly in a concise, practical way. Do not invent
facts that are not in the context or retrieved guidance.
"""

    client = OpenAI(api_key=settings.openai_api_key)
    response = client.responses.create(
        model=settings.openai_model,
        instructions=SYSTEM_PROMPT,
        input=user_prompt,
    )

    return {
        "answer": response.output_text,
        "mode": "openai_grounded",
        "sources": [asdict(x) for x in sources],
    }
