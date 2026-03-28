# Eval Runner Skill

Run architecture benchmark evaluations with fresh AI contexts and aggregate results.

## Usage

```
/eval run <experiment> [--runs N] [--model MODEL]
/eval status
/eval results <experiment>
/eval compare <exp1> <exp2>
```

## How It Works

1. **Reads experiment config** from `evals/<experiment>/config.yml`
2. **Spawns fresh agents** via CLI (`claude --print`) or Task tool
3. **Captures metrics**: files read, files modified, lines changed, tokens
4. **Stores results** in `evals/<experiment>/runs/<timestamp>_<app>.md`
5. **Aggregates** into `evals/<experiment>/results.json`

## Experiment Config

```yaml
# evals/exp1_greenfield/config.yml
name: Greenfield Feature
hypothesis: Co-location reduces files read for new features

apps:
  - vanilla
  - phlex

prompt: |
  Add comment moderation to this Rails app. Requirements:
  1. Comments have status: pending (default), approved, rejected
  2. Only approved comments visible to regular users
  3. Admins see all comments with status badges
  4. Approve/reject buttons for admins
  5. Add tests

  Follow existing patterns. Do not ask clarifying questions.

setup:
  checkout: baseline  # Git tag to start from

metrics:
  - files_read
  - files_modified
  - lines_added
  - lines_deleted
  - test_result
  - tokens_input   # If available
  - tokens_output  # If available
```

## Results Schema

```json
{
  "experiment": "exp1_greenfield",
  "runs": [
    {
      "id": "2026-03-27_001",
      "timestamp": "2026-03-27T14:30:00Z",
      "model": "claude-3-opus",
      "app": "vanilla",
      "metrics": {
        "files_read": 8,
        "files_modified": 13,
        "lines_added": 325,
        "lines_deleted": 52,
        "test_result": "pass",
        "tokens_input": null,
        "tokens_output": null
      },
      "notes": "Sub-agent via Task tool"
    }
  ],
  "summary": {
    "vanilla": { "mean_lines": 273, "std": 0, "n": 1 },
    "phlex": { "mean_lines": 388, "std": 0, "n": 1 }
  }
}
```

## Fresh Context Options

### Option 1: Task Tool (Current)
```ruby
Task(
  prompt: experiment.prompt,
  subagent_type: "general-purpose",
  run_in_background: true
)
```
**Limitation**: Sub-agents inherit parent context.

### Option 2: CLI with --print
```bash
cd vanilla && claude --print "$(cat ../evals/exp1/prompt.txt)" 2>&1 | tee ../evals/exp1/runs/$(date +%s)_vanilla.log
```
**Limitation**: Can't easily capture structured metrics.

### Option 3: API Direct
```ruby
response = Anthropic.messages.create(
  model: "claude-3-opus-20240229",
  messages: [{ role: "user", content: prompt }],
  tools: [...file tools...]
)
```
**Best for**: Precise token counting, true isolation.

## Aggregation

After N runs, calculate:
- Mean and standard deviation for each metric
- Statistical significance (t-test) between architectures
- Confidence intervals

```ruby
def significant?(vanilla_runs, phlex_runs, metric, alpha: 0.05)
  # Two-sample t-test
  t_stat, p_value = TTest.two_sample(
    vanilla_runs.map { |r| r[metric] },
    phlex_runs.map { |r| r[metric] }
  )
  p_value < alpha
end
```

## TODO

- [ ] Implement config.yml parser
- [ ] Add CLI runner with log capture
- [ ] Add API runner with token counting
- [ ] Build aggregation with stats
- [ ] Add `/eval run` slash command
- [ ] Support multiple models
