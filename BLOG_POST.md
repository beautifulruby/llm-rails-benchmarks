# Does Co-locating Views Help AI Code Faster? An Empirical Test

**TL;DR:** I ran the same coding tasks through AI agents on two identical Rails apps—one with traditional ERB views, one with Phlex views co-located in controllers. Results were mixed: co-location helped for logic changes (-38% lines), hurt for UI features (+102% lines), and made no difference for bug fixes. The methodology has significant limitations. N=1 per experiment. Take this as exploratory, not conclusive.

---

## Background: Why I Ran This Experiment

I maintain two Rails applications with very different architectures:

- **App A (Traditional):** 185 services, 104 models, 658-line routes.rb with ~150 custom member actions, ERB views in `app/views/`, Stimulus controllers
- **App B (Co-located):** ~25 models, 220-line routes.rb with everything as resources, Phlex view classes defined inline in controller files

Working with AI assistants on both codebases, I noticed App B *felt* faster to work with. My hypothesis: when views are co-located with controllers, the AI reads fewer files and builds context faster.

Back-of-envelope math suggested a 29.7x token efficiency gain for co-located code:

| Metric | Traditional | Co-located |
|--------|-------------|------------|
| Files to read per feature | 10-15 | 1-2 |
| Estimated tokens | ~58,000 | ~1,950 |

But feelings and napkin math aren't data. So I built a benchmark.

## Methodology

### The Setup

I created two identical Rails 8.1 apps in the same repo:

```
rails-architecture-benchmark/
├── vanilla/    # Traditional: ERB views, separate files
└── phlex/      # Co-located: Phlex views inline in controllers
```

Both apps have the same schema:
- Users (name, email, admin)
- Posts (title, body, user_id)
- Comments (body, post_id, user_id, parent_id, moderation_status)

Same seed data. Same functionality. Only the view architecture differs.

### The Agents

I used Claude with the Task tool to spawn parallel agents—one for each app, given identical prompts. Each agent:
- Started fresh with no prior context about the codebase
- Had access to file reading, editing, and bash commands
- Worked autonomously until tests passed

I measured:
- Files read before first edit
- Total files modified
- Lines of code changed
- Whether tests passed

### The Experiments

**Experiment 1: Greenfield Feature**
> "Add comment moderation (pending/approved/rejected status, admin-only visibility controls, approve/reject buttons)"

**Experiment 2A: Bug Fix**
> "Bug: When deleting a comment with replies, replies remain visible until page refresh. Fix it."

**Experiment 2B: Logic Change**
> "Change visibility: pending comments should be visible to their author, not just admins."

**Experiment 2C: UI Enhancement**
> "Add edit functionality: Edit button, inline form, (edited) timestamp, author/admin authorization."

---

## Results

### Experiment 1: Greenfield Feature

| Metric | Vanilla | Phlex |
|--------|---------|-------|
| Files modified | 13 | 11 |
| Lines added | +325 | +434 |
| Lines deleted | -52 | -46 |
| Net lines | +273 | +388 |

**Result: No meaningful difference.**

Both agents completed the task with passing tests. The Phlex version actually produced *more* code due to the verbosity of Ruby DSL for HTML.

### Experiment 2A: Bug Fix (Turbo Stream)

| Metric | Vanilla | Phlex |
|--------|---------|-------|
| Files read | 8 | 8 |
| Files modified | 2 | 3 |
| Lines added | +23 | +68 |

**Result: No meaningful difference.**

Both agents identified the same root cause (missing Turbo Stream response) and implemented similar fixes. The Phlex agent wrote more test code, but the core fix was equivalent.

### Experiment 2B: Logic Change (Visibility Rules)

| Metric | Vanilla | Phlex | Δ |
|--------|---------|-------|---|
| Files read | 10 | 9 | -10% |
| Files modified | 5 | 4 | -20% |
| Lines added | +163 | +102 | -37% |
| Net change | +146 | +91 | **-38%** |

**Result: Phlex required 38% fewer lines.**

The Phlex agent modified fewer files because the view logic was already in the controller. The Vanilla agent had to update the model, controller, AND a separate view partial.

### Experiment 2C: UI Enhancement (Edit Comments)

| Metric | Vanilla | Phlex | Δ |
|--------|---------|-------|---|
| Files read | 12 | 10 | -17% |
| Files modified | 8 | 9 | +13% |
| Lines added | +130 | +260 | **+100%** |
| Net change | +126 | +255 | **+102%** |

**Result: Vanilla required 49% fewer lines.**

The Phlex Ruby DSL is significantly more verbose than ERB for HTML markup. Adding a form with buttons, labels, and styling requires more Ruby code than the equivalent ERB.

---

## Summary Table

| Experiment | Type | Winner | Line Ratio |
|------------|------|--------|------------|
| 1: Greenfield | New feature | Tie | 1.0x |
| 2A: Bug fix | Cross-cutting | Tie | 1.0x |
| 2B: Logic change | Business rules | Phlex | 0.62x |
| 2C: UI enhancement | Markup-heavy | Vanilla | 0.49x |

---

## Limitations (The Part HN Will Focus On)

### 1. N=1 Per Experiment

Each experiment was run exactly once per architecture. No statistical significance is possible. These results could be noise. A rigorous study would run each experiment 10-30 times and measure variance.

### 2. Sub-Agent Architecture Limitations

I didn't run these as independent AI sessions. I used Claude's Task tool to spawn "sub-agents" from within a parent conversation. This introduces several problems:

**Shared context bleeding:** The sub-agents inherit some context from the parent session. They knew this was a "benchmark experiment," which could affect their behavior (trying harder, being more thorough, etc.). A true test would use completely independent sessions with no knowledge of being tested.

**Cross-contamination:** In one experiment (2A), the Phlex sub-agent accidentally ran `git checkout vanilla/` and reverted the Vanilla agent's changes. I had to manually re-apply them. The agents were nominally independent but operated on the same filesystem.

**Coordination overhead:** I was orchestrating both agents, deciding when to launch them, collecting their outputs, and committing their changes. My decisions about how to prompt them, when to intervene, and how to measure results all introduce experimenter bias.

**Token estimates are rough:** I reported "~2.7M tokens" for the greenfield experiment, but this came from the Task tool's summary, not precise API logs. Sub-agents don't expose exact token counts. The real numbers could be significantly different.

**Not reproducible as-is:** You can't clone this repo and re-run "the same experiment" because the sub-agent orchestration happened in my specific Claude Code session. The prompts are documented, but the exact execution environment isn't reproducible.

**Different behavior than fresh sessions:** Sub-agents may behave differently than a fresh `claude` CLI session. They have access to conversation history, tool results from earlier in the session, and potentially different system prompts. This is not the same as "give a fresh AI this codebase."

### 3. Identical Prompts ≠ Identical Tasks

While I gave identical prompts, the *actual* tasks differed because the codebases differ. The Vanilla app had slightly different code patterns established in the baseline. This could bias results.

### 4. Lines of Code is a Weak Metric

LoC doesn't measure:
- Code quality or correctness
- Time to completion (I didn't measure wall clock time)
- Token usage (I have rough estimates but not exact counts)
- Cognitive load on a human reviewer
- Maintainability of the result

### 5. The Apps Are Trivially Small

These are toy apps with ~500 lines of code each. Real production apps have:
- Complex service objects
- Background jobs
- External API integrations
- Legacy code and technical debt
- Multiple developers' coding styles

The benefits of co-location might scale differently.

### 6. I Built Both Apps

I designed both architectures, which means I unconsciously optimized for my hypothesis. Someone who prefers traditional Rails might structure the Vanilla app differently.

### 7. Phlex-Specific, Not Co-location-Specific

The results conflate two variables:
1. Co-location (views in same file as controller)
2. Phlex DSL (Ruby methods instead of HTML)

The Phlex DSL's verbosity might be masking co-location benefits. A fairer test would compare:
- ERB in separate files vs ERB inline (via `render inline:`)
- Or Phlex in separate files vs Phlex inline

### 8. JavaScript Wasn't Co-located

Both apps kept JavaScript in separate files (or the layout). A true co-location test would use something like inline `<script>` tags or a JS-in-Ruby solution. The bug fix experiment (2A) showed no difference partly because the fix required touching JS.

---

## What I'd Do Differently

### For a More Rigorous Study

1. **Run each experiment 20+ times** with fresh agent sessions
2. **Measure token usage exactly** via API logs
3. **Time to completion** as primary metric
4. **Multiple AI models** (Claude, GPT-4, Gemini, Llama)
5. **Multiple human coders** for comparison
6. **Blind evaluation** of code quality by third parties
7. **Larger, messier codebases** that resemble production
8. **Isolate variables** (co-location vs DSL syntax)

### Alternative Hypotheses to Test

1. **File count matters more than co-location** - Maybe any architecture with fewer files is easier for AI, regardless of what's in them.

2. **Naming conventions matter more** - Maybe `PostsController` + `posts/_comment.html.erb` is fine if the AI can infer relationships from names.

3. **Co-location hurts at scale** - Maybe 500-line controller files are fine, but 5,000-line files are worse than separate files.

4. **Context window is the bottleneck** - Maybe the whole question is obsolete once context windows are 1M+ tokens.

---

## Tentative Conclusions

With all caveats stated, here's what the data *suggests* (not proves):

### Co-location Helps for Logic Changes

When modifying business rules that span model/controller/view, having views inline reduced files touched and lines written. The Phlex agent found all relevant code in one file instead of jumping between three.

**Mechanism:** Less context-gathering overhead. The AI reads one file, sees the whole picture, makes targeted edits.

### Co-location Hurts for UI-Heavy Features

The Phlex Ruby DSL is ~2x more verbose than ERB for HTML markup. Adding forms, buttons, and styling takes more code, which means more tokens to generate.

**Mechanism:** Syntax overhead. `button(class: "bg-blue-600 text-white px-4 py-2") { "Submit" }` is longer than `<button class="bg-blue-600 text-white px-4 py-2">Submit</button>`.

### Cross-Cutting Concerns Negate Benefits

When fixes require touching JavaScript, layouts, or other shared infrastructure, co-location in controllers doesn't help because the relevant code isn't co-located.

**Mechanism:** Co-location only helps when *all* relevant code is co-located. Partial co-location gives partial benefits.

### The Optimal Architecture Might Be Hybrid

Use Phlex components for logic-heavy features (permission checks, conditional rendering, complex state). Use ERB for markup-heavy templates (forms, landing pages, emails).

This matches what I've seen in production: the best codebases use the right tool for each job, not one tool for all jobs.

---

## The Data

All code is at: `github.com/[your-repo]/rails-architecture-benchmark`

```
git checkout baseline     # Both apps before any experiments
git checkout post-greenfield  # After Experiment 1
git log --oneline         # See all experiment commits
```

Each commit message includes the experiment ID, files read, files modified, and lines changed.

---

## Feedback Welcome

This was an afternoon experiment, not a PhD thesis. If you want to:

- Run the experiments yourself and compare results
- Suggest better methodology
- Point out flaws I missed
- Run similar experiments on different architectures

Please do. The more data points, the better our understanding.

And yes, I'm aware that writing this post with an AI assistant is deeply meta. The AI helped with the experiments, the analysis, and the writing. Make of that what you will.

---

*Discuss on [Hacker News](#) | [Twitter](#) | [Email](mailto:)*
