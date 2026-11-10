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

Evaluation tasks derive directly from Flutter's canonical Critical User Journeys (CUJs),
which are the core workflows that developers perform regularly. 
This approach ensures evaluations reflect real-world developer needs rather 
than synthetic puzzles. 

:::note Working in the open
We can't open-source the full evaluation tasks without contaminating 
the benchmark dataset, and instead we publish our canonical list of CUJs. 
With this list, along with the example task below, you can understand 
our evaluation philosophy for FlutterBench.
:::

### Short-horizon vs. long-horizon framing

Tasks are divided into two distinct horizons to evaluate both immediate syntactical
reasoning and long-range architectural planning.

- **Short-horizon tasks**: These challenges test localized implementation,
  widget layout, and framework API mechanics. Each task is self-contained within
  one or two files and can typically be resolved in a single prompt turn.
- **Long-horizon tasks**: These challenges test multi-file refactoring,
  declarative navigation, persistent data synchronization, and state management
  migration. They require the agent to inspect project structure, understand
  dependency boundaries, run static analysis, and iterate over multiple steps.

### Critical User Journeys (CUJs)

Each CUJ represents a combination of:

* A Flutter developer persona (e.g., app developer, plugin developer, full-stack developer)
* A high-level goal
* The specific sequential steps required to achieve that goal

These CUJs are converted into Harbor tasks. Harbor is the framework used to 
run containerized evaluation tasks. CUJs and Harbor tasks don't map cleanly 
one-to-one. Instead, the CUJ list serves as a guide to verify that 
core developer workflows are evaluated. In some cases, 
several CUJs combine into a single task, 
and vice-versa. Our most ambitious evaluations combine multiple Harbor tasks, 
and thus cover many CUJs.

Read the [complete CUJ list](https://docs.flutter.dev/ai/flutter-bench/cujs).

### Dataset

The current dataset includes the following tasks:

| Name | CUJ | Category | Description |
|---|---|---|---|
| Fix Layout Overflows | `overflow-bug` | Short horizon | Diagnose the root cause of layout overflow errors and refactor the layout with flexible, scrolling, or bounding widgets to resolve them. |
| Manage State with Provider | `manage-state-with-provider` | Short horizon | Implement application state management using `package:provider` for dependency injection and reactive updates. |
| Add Localization | `add-localization` | Short horizon | Configure supported languages and locales using standard Flutter internationalization with ARB files and generated localization delegates. |
| Adapt to Material and Cupertino | `adaptive-material-cupertino` | Long horizon | Implement navigation layouts that adaptively render Material Design components on Android and Cupertino components on iOS. |
| Add Web Support | `add-web-support` | Long horizon | Extend an existing application to run on the web, auditing feature and plugin compatibility and scaffolding the platform with official commands. |
| Add Unit, Widget, and Integration Tests | `add-unit-widget-integration-tests` | Long horizon | Achieve comprehensive test coverage with unit, widget, and end-to-end integration test suites using `package:integration_test`. |
| Add Firebase Storage Photos | `firebase-storage` | Long horizon | Integrate `package:firebase_storage` and implement flows to upload, download, and delete photos in cloud storage. |
| Build a Greenfield Fitness App | `greenfield-fitness-app` | Long horizon | Create a new cross-platform Flutter fitness application from scratch, spanning many CUJs across architecture, UI, and data. |

The team is working toward covering all of the workflows in the CUJ list, and new data will be published as we continue work. 

</StoryChapter>

<StoryChapter number="03" title="Grading & scoring design" id="grading-scoring-design">

Every task evaluation is executed **4 independent times** (*K* = 4) from a clean
workspace state to account for non-deterministic model outputs.

### Two-dimension evaluation rubric

Rather than reducing model performance to a simple pass/fail binary, each trial
is scored on a normalized 0.0 to 1.0 scale across two weighted dimensions:

<p class="formula">Result Score = (Outcome × 0.65) + (Quality × 0.35)</p>

<ScoreDimensions>

<DimensionCard title="1. Outcome" icon="check_circle" category="outcome" badge="65% weight">

Outcome measures whether the application compiles and completely fulfills the
functional requirements of the CUJ.

- **Automated test suites**: Unit, widget, and integration test executions.
- **Visual & interaction verification**: Golden file rendering comparisons and
  driver automation confirming UI responsiveness and layout constraints.
- A score of `1.0` indicates that all requirements and assertions passed cleanly.

</DimensionCard>

<DimensionCard title="2. Code Quality" icon="code" category="quality" badge="35% weight">

Code quality measures whether the implementation adheres to production-grade
engineering standards.

- **Static analysis & lints**: Measured via `dart analyze` with strict rules
  from `package:flutter_lints` and `package:dart_flutter_team_lints`.
- **Architectural adherence**: Evaluated using automated AST inspection and
  model-based rubrics graded against human-authored golden solutions.
- Penalties are applied for dead code, raw unchecked mutations, missing type
  annotations, and widget rebuild anti-patterns.

</DimensionCard>

</ScoreDimensions>

### Timed-out and errored trials

A trial that times out or hits an infrastructure error
never counts as a pass.
These trials are also excluded from a task's average
Outcome, Quality, and Result Score,
so those averages reflect only trials that ran to completion.

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

<RollupCard title="Pass Rate (%)" pill="All trials pass" highlight="true">

<p class="formula">Pass Rate = (Tasks where all 4 trials passed ÷ Total Tasks) × 100</p>

</RollupCard>

<RollupCard title="Pass@4 Rate (%)" pill="pass@4">

<p class="formula">Pass@4 = (Tasks with at least 1 trial passed ÷ Total Tasks) × 100</p>

</RollupCard>

<RollupCard title="Average Score (%)" pill="± SD">

<p class="formula">Average Score = (Sum of Task Result Scores ÷ Total Tasks) × 100 (± Standard Deviation)</p>

</RollupCard>

</RollupMetrics>

### Baseline vs. Enhanced

To measure the impact of agent tool augmentation, every model is benchmarked
under two distinct environments:

- **Baseline**: The raw model equipped only with generic command-line execution
  and file read/write tools.
- **Enhanced**: The model equipped with the official Flutter harness,
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
