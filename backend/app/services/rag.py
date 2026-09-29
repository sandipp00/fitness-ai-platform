import re
from dataclasses import dataclass
from .resource_corpus import TRUSTED_RESOURCES


@dataclass(frozen=True)
class RetrievedResource:
    title: str
    publisher: str
    source_url: str
    content: str
    score: int


def _terms(text: str) -> set[str]:
    return {
        t for t in re.findall(r"[a-zA-Z]{3,}", text.lower())
        if t not in {"what", "with", "that", "this", "from", "your", "about"}
    }


def retrieve(query: str, limit: int = 3) -> list[RetrievedResource]:
    q = _terms(query)
    ranked = []

    for item in TRUSTED_RESOURCES:
        haystack = _terms(
            f"{item['title']} {item['publisher']} {item['content']}"
        )
        score = len(q & haystack)
        ranked.append(
            RetrievedResource(
                title=item["title"],
                publisher=item["publisher"],
                source_url=item["source_url"],
                content=item["content"],
                score=score,
            )
        )

    ranked.sort(key=lambda x: x.score, reverse=True)
    return [x for x in ranked[:limit] if x.score > 0] or ranked[:1]
