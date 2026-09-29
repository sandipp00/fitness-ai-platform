from dataclasses import dataclass
from typing import Sequence

import numpy as np
from sklearn.ensemble import RandomForestRegressor

from .ml_features import FEATURE_NAMES, build_features


MODEL_VERSION = "personalization-rf-v1"


@dataclass(frozen=True)
class PersonalizationResult:
    readiness: float
    adherence_probability: float
    recommended_level: str
    model_version: str
    explanation: str


class PersonalizationModel:
    """Small tabular model.

    The initial model is deliberately bootstrap-trained from synthetic
    behavioral patterns. It is a safe engineering scaffold: once enough
    anonymized/consented production history exists, the training dataset can
    be replaced by validated user-level longitudinal outcomes.
    """

    def __init__(self):
        self.model = RandomForestRegressor(
            n_estimators=80,
            max_depth=5,
            random_state=42,
        )
        self._fit_bootstrap()

    def _fit_bootstrap(self):
        rng = np.random.default_rng(42)
        x = []
        y = []

        for _ in range(600):
            avg_steps = rng.uniform(1000, 15000)
            active = rng.uniform(0, 100)
            sleep = rng.uniform(4.5, 9.5)
            step_cons = rng.uniform(0.1, 1.0)
            active_cons = rng.uniform(0.1, 1.0)
            sleep_cons = rng.uniform(0.1, 1.0)
            activity_trend = rng.uniform(-0.5, 0.8)
            sleep_trend = rng.uniform(-0.3, 0.3)
            adherence = rng.uniform(0, 1)

            features = [
                avg_steps, active, sleep, step_cons, active_cons,
                sleep_cons, activity_trend, sleep_trend, adherence
            ]
            readiness = (
                0.25 * min(avg_steps / 10000, 1)
                + 0.25 * min(active / 60, 1)
                + 0.20 * min(max((sleep - 5) / 3, 0), 1)
                + 0.15 * active_cons
                + 0.15 * adherence
            )
            readiness += rng.normal(0, 0.04)
            x.append(features)
            y.append(max(0, min(1, readiness)))

        self.model.fit(np.asarray(x), np.asarray(y))

    def predict(self, series: Sequence[dict]) -> PersonalizationResult:
        features = build_features(series)
        vector = np.asarray([[features[name] for name in FEATURE_NAMES]])
        readiness = float(self.model.predict(vector)[0])

        # Adherence is a transparent behavioral signal rather than a claim
        # about future health outcomes.
        adherence = max(0.0, min(1.0, features["adherence_ratio"] * 0.7
                                  + features["active_consistency"] * 0.3))

        if readiness < 0.40:
            level = "recovery"
        elif readiness < 0.65:
            level = "foundation"
        else:
            level = "progressive"

        if features["activity_trend"] < -0.20:
            explanation = "Recent activity is trending down, so the plan should avoid a sudden intensity increase."
        elif features["activity_trend"] > 0.20 and adherence >= 0.6:
            explanation = "Recent activity and consistency are improving, so gradual progression may be appropriate."
        elif features["avg_sleep_7d"] and features["avg_sleep_7d"] < 6.5:
            explanation = "Recorded sleep is relatively low, so the plan should emphasize recovery and sustainable activity."
        else:
            explanation = "Recent activity and consistency support a gradual, sustainable training structure."

        return PersonalizationResult(
            readiness=round(readiness * 100, 1),
            adherence_probability=round(adherence * 100, 1),
            recommended_level=level,
            model_version=MODEL_VERSION,
            explanation=explanation,
        )


personalization_model = PersonalizationModel()
