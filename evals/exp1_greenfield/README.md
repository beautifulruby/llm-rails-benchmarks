# Experiment 1: Greenfield Feature Implementation

## Hypothesis

Co-located views (Phlex in controller) require fewer files and tokens for new feature implementation compared to traditional Rails (ERB in separate files).

## Prompt

```
Add comment moderation to this Rails app. Requirements:
1. Comments have status: pending (default), approved, rejected
2. Only approved comments visible to regular users
3. Admins see all comments with status badges
4. Approve/reject buttons for admins
5. Add tests

Follow existing patterns. Do not ask clarifying questions.
```

## Method

- Two parallel sub-agents spawned via Claude Task tool
- Each agent given identical prompt
- No prior context about codebase
- Measured: files modified, lines changed, test results

## Expected Outcome

Phlex agent should read fewer files and produce less code due to co-location benefits.

## Actual Outcome

**No significant difference.** Both agents completed successfully with similar token usage (~2.7M each). Phlex actually produced MORE lines due to DSL verbosity.

| Metric | Vanilla | Phlex |
|--------|---------|-------|
| Files modified | 13 | 11 |
| Lines added | +325 | +434 |
| Net change | +273 | +388 |

## Conclusion

Co-location does not provide meaningful benefit for greenfield feature implementation. Both architectures require similar exploration and produce similar amounts of code.
