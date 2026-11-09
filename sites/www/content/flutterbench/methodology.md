---
title: Flutter Bench Methodology
bodyTags: interior flutterbench flutterbench-methodology
description: >-
  Technical methodology and evaluation specification for Flutter Bench,
  measuring AI coding agent capability across Flutter and Dart applications.
---

<FlutterBenchHeader activePage="methodology" />

<StoryChapter number="01" title="Overview & goals" id="overview-goals">

As AI coding agents and large language models increasingly assist software
engineers, measuring their real-world competence on multi-platform application
development has become essential. General-purpose software engineering benchmarks
frequently emphasize algorithmic puzzles or single-file backend scripts in Python
or JavaScript. They fail to assess the specialized skills needed to develop
modern graphical user interfaces: reactive widget composition, lifecycle and
state management, asynchronous streams, cross-platform compilation targets, and
framework-specific toolchains.

Flutter Bench exists to provide an objective, repeatable, and public evaluation
standard for how effectively AI coding agents build, refactor, and debug
Dart and Flutter applications.

### Core questions answered

Flutter Bench is designed to answer three key questions for developers,
enterprises, and AI researchers:

* **Functional correctness**: Can the model produce code that compiles without
   errors, runs cleanly, and satisfies user acceptance criteria across mobile,
   web, and desktop form factors?
* **Architectural fidelity & code quality**: Does the generated code follow
   idiomatic Flutter conventions ([Effective Dart](https://dart.dev/effective-dart)
   and standard architectural patterns like layered state isolation), or does it
   introduce anti-patterns, memory leaks, and brittle workarounds?
* **Harness impact**: How significantly do specialized Flutter developer
   tooling—specifically model context protocol (MCP) servers and agentic
   skills—improve agent success rates compared to raw, unaugmented models?

</StoryChapter>

<StoryChapter number="02" title="Dataset design">

The Flutter Bench dataset is constructed from real-world Critical User Journeys
(CUJs) identified across production Flutter codebases. Tasks are intentionally
divided into two distinct horizons to evaluate both immediate syntactical
reasoning and long-range architectural planning.

### Short-horizon vs. long-horizon framing

- **Short-horizon tasks**: These challenges test localized implementation,
  widget layout, and framework API mechanics. Each task is self-contained within
  one or two files and can typically be resolved in a single prompt turn.
- **Long-horizon tasks**: These challenges test multi-file refactoring,
  declarative navigation, persistent data synchronization, and state management
  migration. They require the agent to inspect project structure, understand
  dependency boundaries, run static analysis, and iterate over multiple steps.

### Critical User Journeys (CUJs)

To prevent benchmark saturation and maintain integrity, individual prompts and
test suites are not public. The evaluation dataset assesses the following
representative journey categories:

<!-- TODO(ewindmill): use component -->
| Category | CUJ Identifier | Description |
|---|---|---|
| Short horizon | `cuj-01-renderflex-overflow` | **Fix RenderFlex Overflow**: Diagnosing and resolving unbounded layout constraints, row/column overflow errors, and proper flex spacing. |
| Long horizon | `cuj-02-adaptive-layout-navigation` | **Navigation with Adaptive Layout**: Implementing responsive multi-pane declarative routing (NavigationRail vs NavigationBar) across mobile, tablet, and desktop breakpoints. |
| Short horizon | `cuj-03-rest-api-http` | **REST API Client: Fetch JSON with http**: Constructing an asynchronous HTTP service with JSON deserialization, model mapping, and network error handling. |
| Short horizon | `cuj-04-provider-state-mgmt` | **Provider State Management**: Implementing reactive application state with `ChangeNotifier`, `ChangeNotifierProvider`, and scoped `Consumer` widgets. |
| Long horizon | `cuj-05-firebase-cloud-storage` | **Firebase Cloud Storage**: Integrating cloud file upload/download flows, transfer progress streams, authentication guards, and exception handling. |
| Long horizon | `cuj-06-dart-genkit-function` | **Dart Genkit Cloud Function**: Authoring serverless Dart AI agent workflows utilizing Firebase Functions and the Genkit Dart SDK. |
| Short horizon | `cuj-07-internationalization-i18n` | **Internationalization (i18n)**: Configuring localization with `.arb` translation catalogs, locale delegates, and localized parameter interpolation. |

</StoryChapter>

<StoryChapter number="03" title="Grading & scoring design" id="grading-scoring-design">

Every task evaluation is executed **4 independent times** (*K* = 4) from a clean
workspace state to account for non-deterministic model outputs.

### Triple-metric evaluation rubric

Rather than reducing model performance to a simple pass/fail binary, each trial
is scored on a normalized 0.0 to 1.0 scale across three weighted dimensions:

<p class="formula">Result Score = (Outcome × 0.60) + (Quality × 0.30) + (Developer Experience × 0.10)</p>

<ScoreDimensions>

<DimensionCard title="1. Outcome" icon="check_circle" category="outcome" badge="60% weight">

Outcome measures whether the application compiles and completely fulfills the
functional requirements of the CUJ.

- **Automated test suites**: Unit, widget, and integration test executions.
- **Visual & interaction verification**: Golden file rendering comparisons and
  driver automation confirming UI responsiveness and layout constraints.
- A score of `1.0` indicates that all requirements and assertions passed cleanly.

</DimensionCard>

<DimensionCard title="2. Code Quality" icon="code" category="quality" badge="30% weight">

Code quality measures whether the implementation adheres to production-grade
engineering standards.

- **Static analysis & lints**: Measured via `dart analyze` with strict rules
  from `package:flutter_lints` and `package:dart_flutter_team_lints`.
- **Architectural adherence**: Evaluated using automated AST inspection and
  model-based rubrics graded against human-authored golden solutions.
- Penalties are applied for dead code, raw unchecked mutations, missing type
  annotations, and widget rebuild anti-patterns.

</DimensionCard>

<DimensionCard title="3. Developer Experience" icon="bolt" category="dx" badge="10% weight">

Developer experience evaluates the ergonomics and efficiency of the agent during
the run:

- Token economy and context utilization.
- Turn count efficiency and tool call precision.
- Absence of thrashing, hallucinated file paths, or circular compilation fixes.

</DimensionCard>

</ScoreDimensions>

### Grader architecture

Grades are assigned through three complementary verification tiers:

1. **Code-based graders**: Hermetic terminal test runners executing `dart test`
   and `flutter test` in sandboxed runtime containers.
2. **Model-based graders**: Multi-turn evaluation prompts with calibrated rubric
   checklists inspecting code style, maintainability, and naming conventions.
3. **Golden solution verification**: Exact AST diff comparison against
   human-verified reference implementations to confirm idiomatic patterns.

### Rollup metrics

The leaderboard aggregates task-level trials into three primary metrics:

<RollupMetrics>

<RollupCard title="Pass Rate (%)" pill="Outcome = 1.0" highlight="true">

<p class="formula">Pass Rate = (Tasks with Outcome = 1.0 ÷ Total Tasks) × 100</p>

</RollupCard>

<RollupCard title="Pass@4 Rate (%)" pill="pass@4">

<p class="formula">Pass@4 = (Tasks with at least 1 trial passed ÷ Total Tasks) × 100</p>

</RollupCard>

<RollupCard title="Average Score (%)" pill="± SD">

<p class="formula">Average Score = (Sum of Task Result Scores ÷ Total Tasks) × 100 (± Standard Deviation)</p>

</RollupCard>

</RollupMetrics>

### Baseline vs. With AI Tooling

To measure the impact of agent tool augmentation, every model is benchmarked
under two distinct environments:

- **Baseline**: The raw model equipped only with generic command-line execution
  and file read/write tools.
- **With AI Tooling**: The model equipped with the official Flutter harness,
  including specialized agent skills (such as `flutter-fix-layout-issues`,
  `dart-run-static-analysis`, and `flutter-add-widget-test`) and the official
  Dart Tooling Daemon MCP server.

</StoryChapter>

<StoryChapter number="04" title="Limitations & caveats" id="limitations-caveats">

While Flutter Bench provides a standardized assessment of agent performance,
several caveats should be considered when interpreting results:

* **Dataset contamination**: Leading foundation models are periodically
   trained on public GitHub repositories. Although task prompts and CUJs in
   Flutter Bench are novel and proprietary, foundational APIs (such as
   `StatefulWidget` or `AnimationController`) are ubiquitous in training corpora.
* **Cost and token variance**: Inference costs fluctuate based on vendor
   pricing models and prompt caching optimizations. Reported costs represent
   standard public API token rates at the time of evaluation.
* **Synthetic boundary conditions**: Real-world application engineering involves
   ambiguous stakeholder requests and legacy technical debt. Flutter Bench CUJs
   provide clear specifications, which may not capture an agent's ability to
   clarify underspecified human intent.
* **Platform-specific runtime nuances**: Benchmark runs are conducted on Linux
   and macOS build runners. Certain platform-specific plugins (such as native
   Android NDK or iOS Metal shaders) are evaluated via abstraction layers rather
   than physical mobile device farms.

To review active agent scores, consult the [Flutter Bench Leaderboard](/flutterbench).

</StoryChapter>
