# Experiment 2C: UI Enhancement (Edit Comments)

## Hypothesis

Co-located views help with UI-heavy features because the AI can see existing patterns and add new UI elements in context.

## Prompt

```
Add the ability to edit comments:
- "Edit" button appears next to delete button
- Clicking edit shows inline form (like reply form)
- Only comment author can edit (and admins)
- Edited comments show "(edited)" timestamp
- Add tests

Follow existing patterns.
```

## Method

- Two parallel sub-agents spawned via Claude Task tool
- Feature requires: migration + model + controller + view + JS + tests
- Measured: files read, files modified, lines changed

## Expected Outcome

Phlex agent might be faster due to seeing existing view patterns inline.

## Actual Outcome

**Vanilla required 49% fewer lines.** The Phlex Ruby DSL is significantly more verbose than ERB for HTML markup.

| Metric | Vanilla | Phlex | Δ |
|--------|---------|-------|---|
| Files read | 12 | 10 | -17% |
| Files modified | 8 | 9 | +13% |
| Lines added | +130 | +260 | **+100%** |
| Net change | +126 | +255 | **+102%** |

## Conclusion

For UI-heavy features, ERB's terseness beats Phlex's co-location benefit. The Ruby DSL for HTML is ~2x more verbose than ERB templates. Adding forms, buttons, and styling takes more code in Phlex.

## Example: Same Button

**ERB (Vanilla):**
```erb
<button onclick="toggleEditForm(<%= comment.id %>)" class="text-blue-500 text-sm hover:underline">
  Edit
</button>
```

**Phlex:**
```ruby
button(
  onclick: "toggleEditForm(#{@comment.id})",
  class: "text-blue-500 text-sm hover:underline"
) { "Edit" }
```

Similar length for simple elements, but forms and complex markup diverge significantly.
