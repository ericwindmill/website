---
title: Flutter Bench
bodyTags: interior flutterbench
description: >-
  Measuring how effectively AI coding agents and models build Flutter and Dart applications.
---

<FlutterBenchPage>

<div class="bench-legend-card">

#### Metric Definitions & Formulas

- **Pass Rate (%)** 
  Percentage of benchmark tasks where the run achieved full outcome success: `count(tasks with Outcome == 1.0) / total tasks × 100`.
- **Pass@4 Rate (%)** Reliability metric representing the percentage of tasks
  where at least 1 of 4 trials passed (`K = 4`).
- **Avg Score (%)** Mean Result Score across the dataset, computed on a
  0.0–1.0 scale as: `Outcome (60%) + Quality (30%) + Developer Experience (10%)`,
  shown with standard deviation (± SD).
- **Avg Tokens & Cost** Mean token consumption and USD cost per task run
  across all evaluations.

</div>

<div class="bench-methodology-card">

### Methodology

Flutter Bench evaluates AI coding agents across realistic
Flutter and Dart development workflows.
Our benchmark includes short-horizon tasks
and multi-file long-horizon challenges.
Every task run is executed across 4 independent trials
to ensure statistical repeatability.
Solutions are graded through a combination of code-based verification suites,
rubric-guided LLM evaluation, and human-verified golden references,
producing an overall Result Score weighted by functional Outcome (60%),
Code Quality (30%), and Developer Experience (10%).
We evaluate each model under both a standalone Baseline harness
and an AI Tooling harness equipped with official Flutter MCP tools and skills.

[Read the complete methodology guide →](/flutterbench/methodology)

</div>

</FlutterBenchPage>

Also consider: 
  'antigravity-cli-1.4.4-gemini-3.8-flash-high-reasoning',

  'antigravity-cli-1.4.4-gemini-4-argon-high-reasoning',

  'antigravity-cli-1.4.4-gemini-4-carbon-high-reasoning',

  'claude-code-2.1.280-claude-opus-5.5-high-reasoning',

  'claude-code-2.1.280-claude-sonnet-5-5-high-reasoning',

  'codex-0.163.0-gpt-6.1-sol-high-reasoning',

  'codex-0.163.0-gpt-6-astra-high-reasoning',