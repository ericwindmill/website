# Flutter Bench data contract — handoff notes

- Schema: [SCHEMA-flutterbench.json](SCHEMA-flutterbench.json) (JSON Schema draft 2020-12, `schemaVersion` 2.0)
- Reference payload: [SCHEMA-flutterbench.example.json](SCHEMA-flutterbench.example.json)

There is no runtime server. This file is committed to the website repository, reviewed once,
built into the leaderboard at `/flutterbench`, and then frozen — a new snapshot lands roughly
every six months and the previous one is archived.

## The shape in one paragraph

Every object carries two layers. **`metrics`** holds precomputed values — these are exactly
what the UI renders, so the numbers published are the numbers that were reviewed, and an
archived snapshot can't be silently restated by a later code change. **`trials`** holds the
raw per-trial measurements those metrics were derived from, committed alongside so a reviewer
can audit the rollups in the same diff, and so a future metric (pass@2, medians, per-category
splits) can be derived without re-running a suite that no longer exists.

```
{ schemaVersion, snapshot{ …, trialsPerTask, scoring }, runs[] }
  run{ agentId, agent, modelId, model, variant, metrics{…}, tasks[] }
    task{ id, name, category, metrics{…}, trials[] }
      trial{ trialIndex, outcome, quality, dx, tokens, cost }
```

**Core invariant: every value under a `metrics` key is a pure function of that scope's
`trials` plus `snapshot.scoring`. Nothing else in the file is derived.** That is what makes
the redundancy safe rather than a second source of truth — see Verification below.

**Scale rule, no exceptions:** raw trial scores are `0.0`–`1.0`; every precomputed score,
rate, and standard deviation is a percentage, `0`–`100`.

## Verification (the part that makes this design work)

Shipping derived values next to their inputs is only safe if something enforces agreement.
CI must re-derive every `metrics` field from `trials` and fail the build on mismatch. Then a
refactor that changes the weighting breaks the build instead of quietly rewriting published
history, and reviewers can trust the committed numbers.

Specifics:

- Re-derive using `snapshot.scoring`, never hardcoded weights — that's what keeps archived
  snapshots computable under a future methodology revision.
- Metrics are stored to at least 4 decimal places; compare with a tolerance of `1e-3`.
- `scoring` weights must sum to exactly `1.0`.
- The check belongs in Dart alongside
  [calculator_test.dart](sites/www/test/flutterbench/calculator_test.dart), reusing
  [BenchCalculator](sites/www/lib/src/utils/bench_calculator.dart) rather than reimplementing
  the formulas — that way the UI's math and the published data are checked against each other,
  and a second implementation can't be the thing that's wrong.

## Formulas

Task level, from its K trials (`mean*` are on the 0–1 scale):

| Field | Definition |
| --- | --- |
| `outcome` / `quality` / `dx` | mean of the trial field × 100 |
| `resultScore` | (meanOutcome × `outcomeWeight` + meanQuality × `qualityWeight` + meanDx × `dxWeight`) × 100 |
| `passedTrialCount` | trials with `outcome >= passThreshold` |
| `passedAnyTrial` / `passedAllTrials` | count > 0 / count == `trialsPerTask` |
| `meanTokens` / `meanCost` | mean of `trials[].tokens` (rounded) / `trials[].cost` |

Run level, from its T tasks:

| Field | Definition |
| --- | --- |
| `passRate` | tasks with `passedAllTrials` ÷ T × 100 |
| `passAtKRate` | tasks with `passedAnyTrial` ÷ T × 100 |
| `avgScore` | mean of `tasks[].metrics.resultScore` |
| `scoreSd` | **sample** SD (n−1 denominator) of those scores; 0 when T == 1 |
| `avgOutcome` / `avgQuality` / `avgDx` | mean of the task field, **unweighted** |
| `avgTokens` / `avgCost` | mean of `tasks[].metrics.meanTokens` / `meanCost` |

`passedTaskCount` and `passAtKTaskCount` ship next to the rates so a reviewer can check a
percentage by eye.

## Deliberate exclusions

- **Deltas aren't precomputed.** Baseline-vs-tooling differences belong to a row pairing this
  file doesn't model, and subtracting two already-reviewed numbers can't drift the way a
  weighted mean can. The UI computes them.
- **No formatted strings.** Send numbers; the UI owns `$0.043`, `85.7% ± 4.2%`, and thousands
  separators. Freezing presentation into data costs responsive truncation and localization.
- **Don't pre-round to display precision.** Store full-ish precision (≥4dp) and let the UI
  round, so a future column can show more detail.

## Things to get right

1. **`meanTokens` / `meanCost` are per-trial means, not per-task totals.** The column reads
   "mean per task run". Summing across K trials inflates it ~4×.
2. **`outcome` is a threshold, not a score.** Only `>= passThreshold` (1.0) counts as a pass;
   `0.99` is a failure. Fractional values still move `resultScore` through the weighting.
3. **`trial.tokens` and `trial.cost` are required in 2.x** (they were optional in 1.x, which
   had no task-level means to audit). Without them the published token and cost figures
   aren't verifiable.
4. **`scoreSd` is the sample SD**, not the population SD.
5. `additionalProperties` is `false` everywhere — an undocumented field is a hard validation
   failure, not silently ignored data. Extend the schema first.

## Constraints the schema can't express — enforce in the producer

- `task.id` unique within a run; `trial.trialIndex` unique and covering `1..K`.
- `trials.length == snapshot.trialsPerTask` for every task.
- All runs in a snapshot cover the same set of `task.id`s.
- At most one run per `(agentId, modelId, variant)`; exactly one published snapshot with
  `status: "current"`.
- `scoring` weights sum to `1.0`.

## The reference payload

[SCHEMA-flutterbench.example.json](SCHEMA-flutterbench.example.json) is the prototype's mock
data converted to this schema: the full roster (6 agent/model pairs × 2 variants = 12 runs,
each with all 7 CUJs × 4 trials), with metrics derived from the trials. Produce a file of this
shape and the leaderboard renders it.

Everything in it is placeholder data authored for UI development — no score, token count,
cost, or version is a real measurement, and the roster is a sample rather than a launch
commitment. The per-trial token and cost splits were synthesized from the prototype's
task-level figures, since 1.x had no per-trial resource data; the splits preserve the
original means exactly.

Checks run on it: schema-valid, every metric re-derives from its trials, and every documented
producer-side invariant holds. Its metrics also reproduce what the prototype UI renders from
[results.json](sites/www/content/flutterbench/results.json) today — max difference 4.4e-5,
identical once formatted for display.

## Open questions

- **Infrastructure failures.** `trial.status` distinguishes `failed` from `error`/`timeout`.
  Whether a harness timeout should count against Pass Rate is a methodology decision, but the
  data has to carry the distinction for that decision to be available at all. Can you send it?
- **Token breakdown.** Input / output / cached splits aren't in the schema. Worth adding if
  you have them — cost auditing, and a likely future column.
- **File layout for the archive.** One file per snapshot (`content/flutterbench/2026-q1.json`)
  or one file containing all of them? One per snapshot is the better fit for "frozen once
  landed" and keeps review diffs small, but the archive index then needs a manifest.

## Consumer-side work (our side, not yours)

1. Models: add `metrics` to `BenchTask` / `BenchModelRun` in
   [bench_models.dart](sites/www/lib/src/models/flutterbench/bench_models.dart) and read
   `AggregateMetrics` from JSON instead of computing it. The computed getters stay — they
   become the verification path, not the render path.
2. Rename `passAt4Rate` → `passAtKRate` and label the column from `snapshot.trialsPerTask`;
   K is a data property, not a constant.
3. Envelope: the loader is path-based, so adopting it is a one-token change in
   [flutterbench_page.dart](sites/www/lib/src/pages/flutterbench_page.dart) —
   `decodeJsonList('flutterbench.results', …)` → `…'flutterbench.results.runs'` — plus
   reading `snapshot` for the "as of" label.
4. Stop swallowing load errors. That page currently wraps the decode in `try { … } catch (_) {}`
   and falls back to an empty list, so a broken data path renders a blank leaderboard instead
   of failing the build. With reviewed-once frozen data, a loud failure is strictly better.
5. Add the CI verification test described above.
