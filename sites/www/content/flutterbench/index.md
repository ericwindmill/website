---
title: Flutter Bench
bodyTags: interior flutterbench
description: >-
  Measuring how effectively AI coding agents and models
  build Flutter and Dart applications.
---

<FlutterBenchPage>

<div class="bench-legend-card">

#### Metric definitions and formulas

- **Avg Score (%)** Mean Result Score across all tasks, computed as
  `Outcome (65%) + Quality (35%)`,
  shown with standard deviation (± SD).
  The leaderboard is sorted by this column by default.
- **Pass@1 (%)** Expected percentage of tasks a model passes
  on a single attempt.
  For each task, this is the share of its trials that passed,
  averaged across all tasks.
  A trial passes only when its Result Score is `1.0`.
- **Pass Rate (%)** Percentage of tasks where every trial passed.
- **Pass@*K* Rate (%)** Percentage of tasks where at least one trial passed.
  *K* is the number of trials a task ran, which can vary between tasks.
- **Avg Tokens & Cost** Mean token consumption and USD cost per task run.
  Cost shows `—` when pricing isn't available for a model.

</div>

<div class="bench-methodology-card">

### Methodology

Flutter Bench evaluates AI coding agents across realistic
Flutter and Dart development workflows.
The benchmark covers tasks ranging from targeted fixes
to building a complete app.
Each task runs multiple independent times
to ensure statistical repeatability.
We grade solutions with a combination of code-based verification suites,
rubric-guided LLM evaluation, and human-verified golden references,
producing an overall Result Score weighted by functional Outcome (65%)
and Quality (35%).

[Read the complete methodology guide →](/flutterbench/methodology)

</div>

</FlutterBenchPage>
