# LLM Rails Architecture Benchmark

Does code architecture affect how efficiently AI assistants work with Rails codebases?

This repo contains two identical Rails apps with different view architectures, plus benchmarks measuring AI agent performance on identical tasks.

## Quick Results

| Experiment | Task Type | Vanilla (ERB) | Phlex (Co-located) | Winner |
|------------|-----------|---------------|-------------------|--------|
| 1: Greenfield | New feature | +273 lines | +388 lines | Tie |
| 2A: Bug fix | Turbo/JS | +24 lines | +67 lines | Tie |
| 2B: Logic change | Visibility rules | +146 lines | +91 lines | **Phlex -38%** |
| 2C: UI feature | Edit form | +126 lines | +255 lines | **Vanilla -51%** |

**TL;DR:** Co-location helps for logic changes, hurts for UI-heavy features, doesn't matter for cross-cutting concerns.

## Documentation

- **[BLOG_POST.md](BLOG_POST.md)** - Full writeup with methodology, results, and limitations
- **[evals/SUMMARY.md](evals/SUMMARY.md)** - Aggregate results table
- **[evals/](evals/)** - Individual experiment READMEs and raw run outputs

## The Apps

```
vanilla/    # Traditional Rails: ERB views in app/views/
phlex/      # Co-located: Phlex view classes in controller files
```

Both apps have identical functionality:
- Users, Posts, Comments (threaded, 3 levels deep)
- Comment moderation (pending/approved/rejected)
- Approve/reject admin actions
- Delete with confirmation
- Edit with (edited) timestamp

## Running Locally

```bash
# Vanilla app
cd vanilla && bin/setup && bin/rails server -p 3001

# Phlex app
cd phlex && bin/setup && bin/rails server -p 3002
```

## Reproducing Experiments

```bash
# Start from baseline (before any experiments)
git checkout baseline

# Or start from post-greenfield (after Experiment 1)
git checkout post-greenfield

# View experiment commits
git log --oneline --grep="Exp 1"
git log --oneline --grep="Exp 2"
```

### Experiment Prompts

**Exp 1 (Greenfield):**
```
Add comment moderation (pending/approved/rejected status, admin visibility controls, approve/reject buttons). Add tests.
```

**Exp 2A (Bug fix):**
```
Bug: When deleting a comment with replies, replies remain visible until page refresh. Fix it.
```

**Exp 2B (Logic change):**
```
Change visibility: pending comments visible to admins AND comment author.
```

**Exp 2C (UI feature):**
```
Add edit functionality: Edit button, inline form, (edited) timestamp, author/admin auth.
```

## Limitations

See [BLOG_POST.md](BLOG_POST.md#limitations-the-part-hn-will-focus-on) for full discussion:

- N=1 per experiment (not statistically significant)
- Sub-agents sharing context, not independent sessions
- Same AI model for all runs
- Token counts are estimates
- Trivially small codebases
- Phlex DSL verbosity conflated with co-location

## Contributing

Want to run your own experiments? PRs welcome:

1. Fork the repo
2. Checkout `baseline` or `post-greenfield` tag
3. Run your experiment with your AI tool
4. Document in `evals/<experiment>/runs/`
5. Submit PR

More data points make this more useful.

## License

MIT
