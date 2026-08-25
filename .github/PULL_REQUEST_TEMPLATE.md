## Summary of Changes

Briefly describe the tool or improvement added to the Awesome Token Optimization Stack.

## Verification Checklist

A pilot benchmark found this stack breaking working fixes while its token-savings
numbers looked great — the run that broke the worst posted the best number. Because
of that, a token/cost number with no correctness evidence next to it is not enough
on its own.

- [ ] **Open Source**: The tool is open-source with an accessible repository.
- [ ] **Correctness Verified**: Tested on a task with a real pass/fail check (a test
      suite, not a vibe check), both with and without the tool, and it didn't break
      the task.
- [ ] **Measurable Savings**: Provides measurable token, cost, or latency reduction —
      reported alongside the correctness check above, not instead of it.
- [ ] **Agent Compatibility**: Verified to work with at least one major coding agent (Claude Code, Cursor, Codex, Aider, etc.).
- [ ] **Reproducible Setup**: Includes clear install, setup, and verification commands.

## Layer Classification

Which layer does this tool belong to?
- [ ] Codebase Intelligence
- [ ] Input Compression
- [ ] Output Compression
- [ ] Monitoring & Observability
- [ ] Model Routing
- [ ] Other (please specify)

## Additional Notes / Benchmarks
Share before/after token savings *and* what happened to correctness — resolved/unresolved
on real tasks, not just a token count. See [the postmortem](https://shreyasht.github.io/token-optimization-stack/)
for why this matters and what "resolved/unresolved" should mean here.
