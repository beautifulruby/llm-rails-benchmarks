# Experiment 2A: Bug Fix (Cross-cutting Concern)

## Hypothesis

Co-located views help with bug fixes because the AI can see all relevant code in one file.

## Prompt

```
Bug report: When deleting a comment with replies, the replies remain visible
until the page is refreshed. They should disappear immediately.

Fix this bug. Add a test to prevent regression.
```

## Method

- Two parallel sub-agents spawned via Claude Task tool
- Each agent starts fresh, no knowledge of previous experiment
- Bug requires understanding: controller action + Turbo/JS integration
- Measured: files read, files modified, lines changed

## Expected Outcome

Phlex agent should fix faster due to seeing view code in controller.

## Actual Outcome

**No significant difference.** Both agents read 8 files and implemented the same fix (Turbo Stream response). The bug was in controller/JS integration, not view logic.

| Metric | Vanilla | Phlex |
|--------|---------|-------|
| Files read | 8 | 8 |
| Files modified | 2 | 3 |
| Lines added | +23 | +68 |

## Conclusion

Co-location doesn't help for cross-cutting concerns (Turbo/JS integration). The relevant code wasn't co-located in either architecture - JavaScript was in layout/separate files.
