---
title: Flutter Bench dataset
bodyTags: interior flutterbench flutterbench-methodology flutterbench-dataset
description: >-
  The tasks in the Flutter Bench dataset,
  including what each task asks for and what it evaluates.
---

<FlutterBenchHeader activePage="dataset" />

<StoryChapter number="01" title="About the dataset" id="about-dataset">

The Flutter Bench dataset is a set of tasks that reflect
the everyday work of Flutter and Dart developers.
Each task starts from a realistic app
and asks an AI coding agent to complete one job,
the way a developer would ask it to in their own project.

The dataset includes two kinds of tasks:

- **Short-horizon tasks** implement a single feature.
  Each one emulates a one-shot request a developer would make
  in an existing app: add a feature, fix a bug, write tests,
  localize the UI, or add a platform.
- **Long-horizon tasks** implement a whole project.
  Each one emulates building a complete app from a product spec,
  or delivering a full milestone in an existing app, over many turns.

Together, the tasks help answer these questions:

- How well do models handle everyday Flutter and Dart work in real apps?
- Do models follow current best practices for Flutter
  and the packages they use, or only produce code that runs?
- Do the Dart and Flutter MCP tools and agent skills improve results?
- Where do models struggle most: understanding an existing codebase,
  using packages, integrating with platforms, or testing?

To learn how tasks are run and scored,
visit the [methodology](/flutterbench/methodology) page.

</StoryChapter>

<StoryChapter number="02" title="Tasks" id="tasks">

For each task, **developer intent** summarizes
what a developer wants to achieve with an agent,
and **evaluates** describes what the task is judging the agent on at a high-level.

The following 14 tasks make up our "MVP dataset". We're actively working
on covering more CUJs.

:::note
To avoid contaminating the benchmark,
we don't publish the full task prompts, starter apps, or graders.
:::

<DatasetTable />

</StoryChapter>
