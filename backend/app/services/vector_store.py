from dataclasses import dataclass
import numpy as np

from .resource_corpus import TRUSTED_RESOURCES

try:
    from sentence_transformers import SentenceTransformer
except Exception:
    SentenceTransformer = None


@dataclass(frozen=True)
class VectorResource:
    title: str
    publisher: str
    source_url: str
    content: str
    score: float


class ResourceVectorStore:
    def __init__(self):
        self.resources = TRUSTED_RESOURCES
        self.model = None
        self.matrix = None

    def _load(self):
        if self.model is not None or SentenceTransformer is None:
            return

        # Small general-purpose model. It is downloaded lazily only when
        # vector retrieval is actually requested.
        self.model = SentenceTransformer("all-MiniLM-L6-v2")
        texts = [
            f"{x['title']} {x['publisher']} {x['content']}"
            for x in self.resources
        ]
        self.matrix = self.model.encode(texts, normalize_embeddings=True)

    def search(self, query: str, limit: int = 3) -> list[VectorResource]:
        try:
            self._load()
        except Exception:
            self.model = None
            self.matrix = None

        if self.model is not None and self.matrix is not None:
            q = self.model.encode([query], normalize_embeddings=True)[0]
            scores = self.matrix @ q
            order = np.argsort(scores)[::-1][:limit]
            return [
                VectorResource(
                    **self.resources[i],
                    score=float(scores[i]),
                )
                for i in order
            ]

        # Deterministic fallback when the embedding model is unavailable.
        terms = set(query.lower().split())
        ranked = []
        for item in self.resources:
            haystack = (
                item["title"] + " " + item["publisher"] + " " + item["content"]
            ).lower()
            score = sum(1 for term in terms if len(term) > 2 and term in haystack)
            ranked.append(VectorResource(**item, score=float(score)))
        ranked.sort(key=lambda x: x.score, reverse=True)
        return ranked[:limit]


vector_store = ResourceVectorStore()
