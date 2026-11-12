---
title: Flutter Bench methodology
bodyTags: interior flutterbench flutterbench-methodology
description: >-
  Technical methodology and evaluation specification for Flutter Bench,
  measuring AI coding agent capability across Flutter and Dart applications.
---

<FlutterBenchHeader activePage="methodology" />

<StoryChapter number="01" title="Overview and goals" id="overview-goals">

As AI coding agents and LLMs increasingly assist software engineers,
measuring their real-world competence on multi-platform 
application development has become essential.
General-purpose software engineering benchmarks frequently emphasize 
algorithmic puzzles or single-file backend scripts in Python or JavaScript.
They don't assess the specialized skills needed to develop modern 
graphical user interfaces: reactive widget composition, 
lifecycle and state management, asynchronous streams, 
cross-platform compilation targets, and framework-specific toolchains.

Flutter Bench provides an objective and repeatable evaluation standard
for how effectively AI coding agents build, refactor, and debug
Dart and Flutter applications.

### Core questions answered

Flutter Bench is designed to answer two questions:

- **Functional correctness**: Can the model produce code that
  compiles without errors, runs cleanly,
  and satisfies user acceptance criteria
  across mobile, web, and desktop form factors?
- **Architectural fidelity and code quality**: Does the generated code follow
  idiomatic Flutter conventions
  ([Effective Dart](https://dart.dev/effective-dart)
  and standard architectural patterns like layered state isolation),
  or does it introduce anti-patterns, memory leaks, and brittle workarounds?

</StoryChapter>

<StoryChapter number="02" title="Dataset design">

Evaluation tasks derive directly from
Flutter's canonical Critical User Journeys (CUJs),
which are the core workflows that developers perform regularly.
This approach ensures that evaluations reflect real-world developer needs
rather than synthetic puzzles.

:::note Working in the open
Publishing the full evaluation tasks would contaminate the benchmark.
Instead, we publish our canonical list of CUJs,
which shows our evaluation philosophy for Flutter Bench.
:::

### Critical User Journeys (CUJs)

Each CUJ represents a combination of:

- A Flutter developer persona
  (for example, app developer, plugin developer, or full-stack developer)
- A high-level goal
- The specific sequential steps required to achieve that goal

We convert CUJs into tasks for Harbor, the framework that runs 
our containerized evaluations. CUJs and Harbor tasks don't map 
cleanly one-to-one. Instead, the CUJ list serves as a guide to verify 
that core developer workflows are evaluated. In some cases, 
several CUJs combine into a single task, and vice versa.
Our most ambitious evaluations combine multiple Harbor tasks,
and thus cover many CUJs.

For the canonical list of Flutter and Dart CUJs, 
visit the [CUJ list](https://docs.flutter.dev/ai/flutter-bench/cujs).
We'll continue to add tasks to Flutter Bench to increase coverage of 
the CUJ list.

### Dataset

The dataset includes the following tasks:

| Name | CUJ | Description |
|---|---|---|
| Fix Layout Overflows | `overflow-bug` | Diagnose the root cause of layout overflow errors and refactor the layout with flexible, scrolling, or bounding widgets to resolve them. |
| Manage State with Provider | `manage-state-with-provider` | Implement application state management using `package:provider` for dependency injection and reactive updates. |
| Add Localization | `add-localization` | Configure supported languages and locales using standard Flutter internationalization with ARB files and generated localization delegates. |
| Adapt to Material and Cupertino | `adaptive-material-cupertino` | Implement navigation layouts that adaptively render Material Design components on Android and Cupertino components on iOS. |
| Add Web Support | `add-web-support` | Extend an existing application to run on the web, auditing feature and plugin compatibility and scaffolding the platform with official commands. |
| Add Unit, Widget, and Integration Tests | `add-unit-widget-integration-tests` | Achieve comprehensive test coverage with unit, widget, and end-to-end integration test suites using `package:integration_test`. |
| Add Firebase Storage Photos | `firebase-storage` | Integrate `package:firebase_storage` and implement flows to upload, download, and delete photos in cloud storage. |
| Build a Greenfield Fitness App | `greenfield-fitness-app` | Create a new cross-platform Flutter fitness application from scratch, spanning many CUJs across architecture, UI, and data. |

</StoryChapter>

<StoryChapter number="03" title="Grading and scoring design" id="grading-scoring-design">

We run each task **4 independent times** (*K* = 4),
each from a clean workspace,
to account for nondeterministic model output.

### Two-dimension evaluation rubric

Rather than reducing model performance to a pass/fail binary,
we score each trial on a normalized 0.0 to 1.0 scale
across two weighted dimensions:

<p class="formula">Result Score = (Outcome × 0.65) + (Quality × 0.35)</p>

<ScoreDimensions>

<DimensionCard title="1. Outcome" icon="check_circle" category="outcome" badge="65% weight">

Outcome measures whether the application compiles
and completely fulfills the functional requirements of the CUJ.

- **Automated test suites**: Unit, widget, and integration test executions.
- **Visual and interaction verification**: Golden file rendering comparisons
  and driver automation confirming UI responsiveness and layout constraints.
- **Scoring**: A score of `1.0` indicates that
  all requirements and assertions passed cleanly.

</DimensionCard>

<DimensionCard title="2. Quality" icon="code" category="quality" badge="35% weight">

Quality measures whether the implementation adheres to
production-grade engineering standards.

- **Static analysis and lints**: Measured with `dart analyze`
  using strict rules from `package:flutter_lints`
  and `package:dart_flutter_team_lints`.
- **Architectural adherence**: Evaluated using automated AST inspection
  and model-based rubrics graded against human-authored golden solutions.
- **Penalties**: The grader penalizes dead code, raw unchecked mutations,
  missing type annotations, and widget rebuild anti-patterns.

</DimensionCard>

</ScoreDimensions>

### Timed-out and errored trials

A trial that times out or hits an infrastructure error
never counts as a pass.
These trials are also excluded from a task's average
Outcome, Quality, and Result Score,
so those averages reflect only trials that ran to completion.

### Grader architecture

Three complementary verification tiers assign grades:

- **Code-based graders**: Hermetic terminal test runners
   executing deterministic tooling like `dart analyze` and `flutter test`
   in sandboxed runtime containers.
- **Model-based graders**: Multi-turn evaluation prompts
   with calibrated rubric checklists
   inspecting code style, maintainability, and naming conventions.
- **Golden solution verification**: AST diff comparison
   against human-verified reference implementations
   to confirm idiomatic patterns.

### Rollup metrics

The leaderboard aggregates task-level trials into three primary metrics:

<div class="table-wrapper">
<table class="rollup-metrics-table">
  <tbody>
    <tr>
      <td><strong>Pass Rate (%)</strong></td>
      <td><code>pass^4</code></td>
      <td>Pass Rate = (Tasks where all 4 trials passed ÷ Total Tasks) × 100</td>
    </tr>
    <tr>
      <td><strong>Pass@4 Rate (%)</strong></td>
      <td><code>pass@4</code></td>
      <td>Pass@4 = (Tasks with at least 1 trial passed ÷ Total Tasks) × 100</td>
    </tr>
    <tr>
      <td><strong>Average Score (%)</strong></td>
      <td><code>± SD</code></td>
      <td>Average Score = (Sum of Task Result Scores ÷ Total Tasks) × 100 (± Standard Deviation)</td>
    </tr>
  </tbody>
</table>
</div>

</StoryChapter>

<StoryChapter number="04" title="Limitations and caveats" id="limitations-caveats">

Flutter Bench provides a standardized assessment of agent performance,
but keep these caveats in mind when you interpret results:

- **Dataset contamination**: Leading foundation models
  are periodically trained on public GitHub repositories.
  Although task prompts and CUJs in Flutter Bench are novel and proprietary,
  foundational APIs (such as `StatefulWidget` or `AnimationController`)
  are ubiquitous in training corpora.
- **Cost and token variance**: Inference costs fluctuate
  based on vendor pricing models and prompt caching optimizations.
  Reported costs represent standard public API token rates
  at the time of evaluation.
- **Synthetic boundary conditions**: Real-world application engineering
  involves ambiguous stakeholder requests and legacy technical debt.
  Flutter Bench CUJs provide clear specifications,
  which might not capture an agent's ability
  to clarify underspecified human intent.
- **Platform-specific runtime nuances**: Benchmarks run
  on Linux and macOS build runners.
  Certain platform-specific features
  (such as native Android NDK code or iOS Metal shaders)
  are evaluated through abstraction layers
  rather than physical mobile device farms.

To review active agent scores, consult the [Flutter Bench leaderboard](/flutterbench).

</StoryChapter>
