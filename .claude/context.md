# Session Context: LLM Rails Architecture Benchmark

## What This Repo Is

A benchmark for measuring how code architecture affects AI agent efficiency on Rails tasks. Two identical apps (vanilla ERB vs Phlex co-located views), same features, measured results.

## Key Findings (2026-03-27 Session)

| Task Type | Winner | Why |
|-----------|--------|-----|
| Greenfield | Tie | Both need same exploration |
| Bug fix (cross-cutting) | Tie | JS wasn't co-located |
| Logic change | Phlex -38% | View logic in same file |
| UI feature | Vanilla -51% | ERB more concise than Phlex DSL |

## Repo Structure

```
vanilla/                    # Traditional Rails + ERB
phlex/                      # Phlex views in controllers
evals/
├── SUMMARY.md              # Aggregate results
├── exp1_greenfield/
│   ├── README.md           # Hypothesis, method, results
│   └── runs/               # Raw agent outputs per run
├── exp2a_bugfix/
├── exp2b_visibility/
└── exp2c_edit/
BLOG_POST.md                # Full writeup for publication
```

## How Experiments Were Run

1. Spawned parallel sub-agents via Task tool
2. Gave identical prompts to vanilla and phlex agents
3. Agents worked autonomously until tests passed
4. Collected: files read, files modified, lines changed
5. Committed with structured messages: `Exp 2A (Vanilla): ...`

## Methodology Limitations

- **N=1** - Each experiment run once per architecture
- **Sub-agents share context** - Not truly independent sessions
- **Cross-contamination** - Agents operated on same filesystem
- **Token estimates rough** - No precise API logging
- **Not reproducible** - Can't replay exact session

## Future Improvements Needed

1. **Fresh CLI sessions** - Use `claude --print` or API instead of sub-agents
2. **Precise token logging** - Capture exact input/output tokens
3. **Multiple runs** - N=10+ for statistical significance
4. **Multiple models** - GPT-4, Gemini, Claude variants
5. **Larger codebases** - Scale beyond toy apps
6. **Isolated variables** - Test co-location vs DSL separately

## Tags

- `baseline` - Both apps before any experiments
- `post-greenfield` - After Experiment 1

## GitHub

https://github.com/beautifulruby/llm-rails-benchmarks
