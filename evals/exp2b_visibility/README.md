# Experiment 2B: Feature Modification (Logic Change)

## Hypothesis

Co-located views help when modifying business logic that spans model/controller/view because all relevant code is visible in fewer files.

## Prompt

```
Change the comment visibility rules:
- Approved comments: visible to everyone
- Pending comments: visible to admins AND the comment author
- Rejected comments: visible only to admins

Update tests accordingly.
```

## Method

- Two parallel sub-agents spawned via Claude Task tool
- Change requires understanding: model scopes + controller filtering + view conditionals
- Measured: files read, files modified, lines changed

## Expected Outcome

Phlex agent should require fewer file reads and produce less code because view logic is in the controller.

## Actual Outcome

**Phlex required 38% fewer lines.** The co-located views meant the agent could see model-controller-view logic in fewer files.

| Metric | Vanilla | Phlex | Δ |
|--------|---------|-------|---|
| Files read | 10 | 9 | -10% |
| Files modified | 5 | 4 | -20% |
| Lines added | +163 | +102 | -37% |
| Net change | +146 | +91 | **-38%** |

## Conclusion

Co-location provides measurable benefit for logic changes that span multiple architectural layers. The Phlex agent modified fewer files and wrote less code.
