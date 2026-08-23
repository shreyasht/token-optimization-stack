# Benchmarking Methodology

Purpose: verify the token and cost savings claims in [TOKEN_OPTIMIZATION_STACK.md](TOKEN_OPTIMIZATION_STACK.md) with measured data instead of unsupported point figures.

**Status: not yet run.** This document defines the methodology. Results get appended here once benchmark runs complete — this is not itself a results doc.

## Repo tiers

### Verified tier (ground-truth pass/fail)

Tasks in this tier ship with a known-good fix and a test suite that determines pass/fail. Use this tier for any claim that pairs token savings with task correctness — a compression tool that saves tokens but breaks the fix is a loss, not a win.

**Python — [SWE-bench Verified](https://www.swebench.com/):**
- django/django
- sympy/sympy
- scikit-learn/scikit-learn
- matplotlib/matplotlib
- sphinx-doc/sphinx
- pytest-dev/pytest
- psf/requests
- pallets/flask
- pylint-dev/pylint
- astropy/astropy
- mwaskom/seaborn
- pydata/xarray

**Java — [Multi-SWE-bench](https://github.com/multi-swe-bench/multi-swe-bench) / SWE-bench-java-verified:**
- alibaba/fastjson2
- elastic/logstash
- mockito/mockito
- FasterXML/jackson-databind (SWE-bench-java-verified — largest single contributor, ~54% of that dataset's issues)

### Scale tier (size stress only, no ground truth)

- spring-projects/spring-boot (~1.06M LOC total, ~872K Java, measured via shallow clone)
- micronaut-projects/micronaut-core (~832K LOC total, ~477K Java, measured via shallow clone)

Neither is in a verified SWE-bench dataset. Before using either for a correctness claim, curate a small set of real closed-issue/merged-PR pairs by hand (issue text + PR diff + the tests that prove the fix) and confirm the fix actually resolves the issue. Until that curation exists, this tier is for token/cost/latency measurement only — do not report task-success numbers from it.

## Task sampling

- Stratified random sample per repo, not cherry-picked.
- Minimum 20 tasks per repo in the verified tier for the full run, so one repo's noise doesn't dominate the aggregate.
- Fixed, versioned task list committed to this repo (`benchmarks/tasks.json`, not yet created) so any run is reproducible from the same input set.
- **Cheap-first, not full-matrix-first.** The full 20-tasks-per-repo × 5-arm × 3-repeat matrix is expensive (thousands of agent runs). Before committing to it, run a small stratified pilot sample — e.g. 2 tasks per repo across every repo tier, not concentrated in one or two repos — under a reduced arm set (see below) to check the effect is real. Only escalate to the full matrix once the pilot shows a consistent signal worth the spend.

## Ablation design

The stack table in `TOKEN_OPTIMIZATION_STACK.md` attributes savings to individual tools (Graphify, Serena, LeanCTX, Caveman). A single baseline-vs-full-stack run only supports an aggregate "the whole stack" number — it cannot support per-tool attribution. To back the per-tool figures, run each stage as its own arm, changing exactly one variable per step:

1. baseline (no stack)
2. + Graphify
3. + Graphify + Serena
4. + Graphify + Serena + LeanCTX
5. + Graphify + Serena + LeanCTX + Caveman

Headroom and LiteLLM were dropped from the stack and this ablation design: Headroom's `headroom init claude` registration path (the only one usable without stacking a separate `wrap`/`proxy` launcher around the invocation) turned out to register an on-demand MCP tool the agent may never call, not the transparent compression the doc originally claimed — and its `mcp serve` subcommand crashed outright against a current `mcp` SDK install in `token-stack-benchmarks` testing (needs a `mcp<2` pin, and a lot of scope for its own bugs). LiteLLM was already deferred (see git history) since its `usage-based-routing-v2` is a load-balancing strategy, not the complexity-based routing the doc described, and Claude Code sends one fixed model per `-p` session. Both added complexity disproportionate to what they measurably deliver for this stack; removed rather than kept as unverified/broken claims.

**Reduced arm set for pilot runs.** The 5-arm progression above is required to back the per-tool attribution numbers, but it costs 5x a single comparison. For an initial "does this hypothesis hold at all" pass, running only arm 1 (baseline) and arm 5 (full stack) is a defensible, documented tradeoff — it answers "does the stack save tokens without breaking correctness" cheaply, at the cost of not knowing which individual tool did the work or whether one tool's savings are being masked by another tool's regression. Treat any 2-arm result as directional only; per-tool claims still require the full 5-arm run.

## Controlled run conditions

- Model and model version pinned for the entire batch — no silent provider-side model updates mid-run (`token-stack-benchmarks`'s `run-task.sh` takes explicit `--model`/`--effort` flags for this; a run without them falls back to whatever the CLI's own default is at run time, which is not a pin and should not be used for a reported batch).
- Identical tool access and system prompt shape across arms, except the one variable under test.
- Minimum 3 repeats per task per arm. LLM output is non-deterministic; one run is an anecdote, not a measurement.

## Metrics captured per run

- Input tokens
- Output tokens
- Total cost (USD, at the pinned model's published rate)
- Wall-clock time
- Tool-call count
- Pass/fail (verified tier only)

Capture via Agentsview (`agentsview wrap` or the MCP server) rather than hand-logging — it's already part of the stack under test.

## Reporting format

Report, per repo tier and per arm:
- median
- IQR or min–max range
- n (number of task × repeat runs the figure is based on)
- link to raw run logs or a commit hash for the task list used

No single point figures. This replaces claims like "70–90% fewer input tokens" with a number that has a defined sample behind it.

## Open items

- [x] `tasks/tasks.json` — fixed, versioned task list per repo (in `token-stack-benchmarks`, not `benchmarks/tasks.json` — path corrected here to match; generated by `scripts/pull-tasks.py` from SWE-bench Verified + Multi-SWE-bench, seed 42, 231 tasks)
- [ ] Curated issue/PR pairs for spring-boot and micronaut-core (scale-tier correctness)
- [x] Pilot sample — `tasks/sample-30.json` in `token-stack-benchmarks` (2 tasks per repo, all 16 repos in `tasks/tasks.json`, 31 tasks total), run via `scripts/run-and-compare.sh --tasks-file tasks/sample-30.json --arms baseline,caveman` (the 2-arm reduced set above)
- [ ] Pilot results reviewed — confirm the effect holds before committing to the full 20-tasks-per-repo × 5-arm × 3-repeat matrix
- [ ] Results published back into this file, replacing the "not yet run" status above

## References

- [SWE-bench Verified](https://www.swebench.com/)
- [Multi-SWE-bench (GitHub)](https://github.com/multi-swe-bench/multi-swe-bench)
- [Multi-SWE-bench: A Multilingual Benchmark for Issue Resolving (arXiv)](https://arxiv.org/html/2504.02605v1)
