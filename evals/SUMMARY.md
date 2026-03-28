# Evaluation Summary

## Overview

4 experiments comparing AI agent performance on two Rails architectures:
- **Vanilla:** Traditional ERB views in `app/views/`
- **Phlex:** Co-located Phlex views in controller files

## Results Table

| Exp | Type | Vanilla Files | Phlex Files | Vanilla Lines | Phlex Lines | Winner |
|-----|------|---------------|-------------|---------------|-------------|--------|
| 1 | Greenfield | 13 | 11 | +273 | +388 | Tie |
| 2A | Bug fix | 2 | 3 | +24 | +67 | Tie |
| 2B | Logic change | 5 | 4 | +146 | +91 | **Phlex** |
| 2C | UI enhancement | 8 | 9 | +126 | +255 | **Vanilla** |

## Key Findings

### Co-location Helps When...
- Modifying business logic that spans model/controller/view
- Changes require understanding how data flows through layers
- Example: Visibility rules (Exp 2B)

### Co-location Hurts When...
- Adding lots of HTML markup (forms, buttons, styling)
- The Phlex DSL is more verbose than ERB
- Example: Edit feature (Exp 2C)

### Co-location Doesn't Matter When...
- Bug involves cross-cutting concerns (JS, Turbo)
- Relevant code isn't actually co-located
- Example: Turbo Stream bug fix (Exp 2A)

## Methodology Notes

- N=1 per experiment (not statistically significant)
- Sub-agents, not independent sessions
- Same AI model (Claude) for all runs
- Token counts are estimates
- See BLOG_POST.md for full limitations

## Reproduction

```bash
git checkout baseline        # Before any experiments
git checkout post-greenfield # After Exp 1

# View specific experiments
git log --oneline --grep="Exp 1"
git log --oneline --grep="Exp 2A"
git log --oneline --grep="Exp 2B"
git log --oneline --grep="Exp 2C"
```

## Directory Structure

```
evals/
├── SUMMARY.md (this file)
├── exp1_greenfield/
│   ├── README.md
│   └── runs/
│       ├── 2026-03-27_vanilla.md
│       └── 2026-03-27_phlex.md
├── exp2a_bugfix/
│   ├── README.md
│   └── runs/...
├── exp2b_visibility/
│   ├── README.md
│   └── runs/...
└── exp2c_edit/
    ├── README.md
    └── runs/...
```
