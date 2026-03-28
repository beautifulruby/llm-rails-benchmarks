---
description: Run architecture benchmark evaluations
arguments:
  - name: action
    description: "run, status, or results"
  - name: experiment
    description: "Experiment ID (e.g., exp2b_visibility)"
    required: false
---

# Eval Runner

You are running an architecture benchmark evaluation.

## Available Actions

### `run <experiment>`
1. Read `evals/<experiment>/config.yml` for experiment details
2. Checkout the specified git tag
3. For each app (vanilla, phlex):
   - Spawn a fresh sub-agent with the prompt
   - Let it work until tests pass
   - Capture: files read, files modified, lines changed
4. Save results to `evals/<experiment>/runs/<timestamp>_<app>.md`
5. Update `evals/<experiment>/results.json`

### `status`
Read `evals/manifest.yml` and report:
- Completed experiments with results
- Planned experiments
- Current run counts vs target

### `results <experiment>`
Read `evals/<experiment>/results.json` and display:
- Comparison table
- Winner and ratio
- Statistical significance (if N > 1)

## Important Notes

- Sub-agents share parent context (limitation)
- For true isolation, user should run via CLI: `claude --print`
- Always commit agent work with structured message: `Exp <ID> (<app>): <description>`
- After runs, update `evals/manifest.yml` with new counts

## Current Experiments

- exp1_greenfield: Greenfield feature (complete, N=1)
- exp2a_bugfix: Bug fix (complete, N=1)
- exp2b_visibility: Logic change (complete, N=1, winner=phlex)
- exp2c_edit: UI enhancement (complete, N=1, winner=vanilla)

## Running an Experiment

```
User: /eval run exp2b_visibility

1. Read evals/exp2b_visibility/config.yml
2. git checkout post-greenfield
3. Spawn vanilla agent with prompt
4. Spawn phlex agent with prompt
5. Collect results
6. Update results.json
```
