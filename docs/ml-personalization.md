# ML personalization

## Current model

The first ML layer uses a small Random Forest regressor over longitudinal
behavior features:

- 7-day average steps
- 7-day average active minutes
- 7-day average sleep
- steps consistency
- activity consistency
- sleep consistency
- activity trend
- sleep trend
- activity adherence ratio

The output is a **readiness signal** used to select a conservative plan level:
`recovery`, `foundation`, or `progressive`.

### Important modeling boundary

The bootstrap model is trained on synthetic behavioral patterns. It is an
engineering scaffold, not a clinically validated model and not a predictor of
health outcomes.

The correct production path is to replace the bootstrap training set with a
consented, privacy-preserving longitudinal dataset and evaluate the model
against a clearly defined outcome before using it to influence training plans.

## API

```text
GET /api/analytics/personalization
```

Returns:
- model version
- readiness signal
- adherence signal
- recommended level
- explanation
- aggregate features

## Future production ML

1. Define a measurable outcome such as plan adherence.
2. Collect explicit user consent for model training.
3. Remove direct identifiers.
4. Split users by person, not by row, for train/validation/test.
5. Avoid leakage from future activity.
6. Compare against a rule-based baseline.
7. Calibrate and monitor performance.
8. Version models and training datasets.
9. Add drift monitoring.
10. Keep a conservative rules layer as the safety boundary.
