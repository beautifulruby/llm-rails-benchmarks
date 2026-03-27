# Rails Architecture Benchmark

**Hypothesis:** Co-located code (Phlex views in controllers) enables faster AI-assisted feature development than traditional Rails (ERB views in separate files).

## Background

This experiment originated from comparing two production Rails apps:

- **Garry's List (GL):** 185 services, 104 models, 89 jobs, 658-line routes.rb with ~150 custom member actions
- **OpenGraphPlus (OGP):** ~25 models, ~6 jobs, 220-line routes.rb with everything as resources

### Key Architectural Differences Observed

| Pattern | Garry's List | OpenGraphPlus |
|---------|--------------|---------------|
| Views | ERB in `app/views/` | Phlex classes in controller files |
| Routes | Custom actions (`post :approve`) | Nested resources (`resource :approval`) |
| Frontend | Stimulus controllers | Inline JS with `onclick: safe()` |
| State | Stimulus + Turbo Streams | Turbo Page Refreshes (morphing) |
| Controllers | 1,326 lines (admin/posts) | 120 lines (includes model + views) |
| Commit size | Avg 475 insertions | Avg 103 insertions (4.6x smaller) |

### Estimated Token Efficiency for AI

When an AI needs to understand a feature:

| Metric | Traditional (GL-style) | Co-located (OGP-style) |
|--------|------------------------|------------------------|
| Files to read | 10-15 | 1-2 |
| Tokens per feature | ~58,000 | ~1,950 |
| Tool calls | 12-15 | 2-3 |
| **Efficiency gain** | baseline | **29.7x fewer tokens** |

This experiment aims to empirically validate these estimates.

## The Experiment

Two identical Rails apps. Same feature. Different architectures. Measured results.

### The Apps

| Directory | Architecture |
|-----------|--------------|
| `vanilla/` | Traditional Rails: ERB views, Stimulus controllers, custom routes |
| `phlex/` | Modern Rails: Phlex views in controllers, inline JS, everything is a resource |

### Baseline (Both Apps)

- Posts (title, body, user_id)
- Comments (body, post_id, user_id, parent_id)
- Users (name, email)
- Basic CRUD working (posts show/create/edit/destroy, comments create/destroy)
- Threaded comments up to 3 levels deep
- Seed data (3 users, 3 posts, 9 comments)

#### Baseline File Counts

| Metric | Vanilla | Phlex |
|--------|---------|-------|
| Controller/View files | 15 | 3 |
| Lines of code | 245 | 343 |
| **Files to read for context** | 10 | 1 |

The Phlex version has more lines but **90% fewer files to open**.

### The Feature: Threaded Comments

Add to both apps:

1. Comments can have replies (nested via parent_id)
2. Display nested up to 3 levels deep
3. "Reply" button opens inline form
4. Collapse/expand thread UI
5. Delete comment with confirmation (cascades to children)
6. Approve/reject moderation for comments

### What We Measure

| Metric | How |
|--------|-----|
| Files created | `git diff --stat` |
| Files modified | `git diff --stat` |
| Lines of code | `wc -l app/**/*.rb app/**/*.erb` |
| Input tokens | Bytes read by AI ÷ 4 |
| Output tokens | Bytes written by AI ÷ 4 |
| Tool calls | Count of Read/Edit/Write/Bash |
| Wall clock time | Start to passing tests |
| Test iterations | Number of test runs before green |

## Results

### Experiment 1: Greenfield Implementation (Parallel AI Agents)

**Method:** Two parallel AI agents given identical prompts, no prior context about the codebase.

**Prompt used:**
```
Add comment moderation to this Rails app. Requirements:
1. Comments have status: pending (default), approved, rejected
2. Only approved comments visible to regular users
3. Admins see all comments with status badges
4. Approve/reject buttons for admins
5. Add tests

Follow existing patterns. Do not ask clarifying questions.
```

### Vanilla Rails (Greenfield)

```
Files modified: 13
Lines added: 325
Lines deleted: 52
Net lines: +273

Files touched:
  - app/controllers/application_controller.rb
  - app/controllers/comments_controller.rb
  - app/controllers/posts_controller.rb
  - app/javascript/application.js
  - app/models/comment.rb
  - app/models/user.rb
  - app/views/posts/_comment.html.erb
  - config/routes.rb
  - db/schema.rb
  - db/seeds.rb
  - test/fixtures/*.yml
  - test/models/comment_test.rb

Total tokens: ~2.7M
Tests: 34 assertions, all passing
```

### Phlex Rails (Greenfield)

```
Files modified: 11
Lines added: 434
Lines deleted: 46
Net lines: +388

Files touched:
  - app/controllers/comments_controller.rb
  - app/controllers/posts_controller.rb
  - app/models/comment.rb
  - app/views/layouts/application.html.erb
  - config/routes.rb
  - db/schema.rb
  - db/seeds.rb
  - test/fixtures/*.yml
  - test/models/comment_test.rb

Total tokens: ~2.7M
Tests: 36 assertions, all passing
```

### Greenfield Comparison

| Metric | Vanilla | Phlex | Notes |
|--------|---------|-------|-------|
| Files touched | 13 | 11 | -15% (2 fewer files) |
| Lines added | 325 | 434 | +33% (Phlex DSL is verbose) |
| Net lines | +273 | +388 | Phlex views inline = more code |
| Total tokens | ~2.7M | ~2.7M | **No significant difference** |

**Greenfield Conclusion:** For new feature implementation, both architectures performed similarly. The agents spent similar time on exploration, implementation, and testing. The hypothesized efficiency gain was NOT observed in greenfield development.

**Why?** Greenfield implementation requires:
1. Understanding requirements (same for both)
2. Creating new code (Phlex actually requires more lines)
3. Running tests and fixing issues (similar complexity)

The efficiency hypothesis may apply more to **iterative development** where:
- Developer needs to read existing code to understand it
- Change requests require modifying multiple related files
- Bug fixes require tracing through scattered code

---

## Experiment 2: Iterative Development

Testing whether co-location helps with **modifying existing features**.

### Experiment 2A: Bug Fix (Turbo Stream Deletion)

**Prompt:**
```
Bug report: When deleting a comment with replies, the replies remain visible
until the page is refreshed. They should disappear immediately.

Fix this bug. Add a test to prevent regression.
```

**Results:**

| Metric | Vanilla | Phlex | Notes |
|--------|---------|-------|-------|
| Files read | 8 | 8 | Similar exploration needed |
| Files modified | 2 | 3 | Phlex had JS in layout |
| Lines added | +23 | +68 | Phlex added more tests |

**Vanilla Fix:**
- Modified `comments_controller.rb` destroy action
- Added turbo_stream.remove response
- 1 test added

**Phlex Fix:**
- Modified `comments_controller.rb` destroy action
- Modified `application.html.erb` (JS for modal)
- 2 tests added

**Conclusion:** No significant difference. Both required reading the same types of files (controller, model, views/layout, tests). The Phlex "views in controller" didn't help because the JavaScript was still in a separate file (layout).

### Experiment 2B: Feature Modification (Visibility Rules)

**Prompt:**
```
Change the comment visibility rules:
- Approved comments: visible to everyone
- Pending comments: visible to admins AND the comment author
- Rejected comments: visible only to admins

Update tests accordingly.
```

**Results:**

| Metric | Vanilla | Phlex | Ratio |
|--------|---------|-------|-------|
| Files read | 10 | 9 | -10% |
| Files modified | 5 | 4 | -20% |
| Lines added | +163 | +102 | -37% |
| Lines deleted | -17 | -11 | — |
| Net lines | +146 | +91 | **-38%** |

**Vanilla Implementation:**
- Modified: model, controller, view partial, 2 test files
- Required understanding how visibility is checked in 3 locations

**Phlex Implementation:**
- Modified: model, controller (includes views), 2 test files
- View logic co-located with controller, one less file to touch

**Conclusion:** Phlex required **38% fewer lines** and **20% fewer files**. The co-located views made it easier to see all visibility-related code in one place. The controller file serves as a single source of truth for "how does this feature look and behave?"

### Experiment 2C: UI Enhancement (Edit Comments)

**Prompt:**
```
Add the ability to edit comments:
- "Edit" button appears next to delete button
- Clicking edit shows inline form (like reply form)
- Only comment author can edit (and admins)
- Edited comments show "(edited)" timestamp
- Add tests

Follow existing patterns.
```

**Results:**

| Metric | Vanilla | Phlex | Ratio |
|--------|---------|-------|-------|
| Files read | 12 | 10 | -17% |
| Files modified | 8 | 9 | +13% |
| Lines added | +130 | +260 | **+100%** |
| Net lines | +126 | +255 | **+102%** |

**Vanilla Implementation:**
- Migration + model + controller + view partial + JS + tests
- Each layer has a dedicated file

**Phlex Implementation:**
- Same layers but views are inline in controller
- More lines because Ruby DSL is more verbose than ERB
- Added Phlex components: `EditCommentForm`, modified `CommentView`

**Conclusion:** **Vanilla wins** for new UI features. The Phlex Ruby DSL for HTML is significantly more verbose than ERB templates. While co-location reduces file count, it increases total lines of code. For features that are primarily about UI (forms, buttons, styling), ERB's terseness is advantageous.

---

### Experiment 2 Summary

| Experiment | Type | Winner | Ratio (lines) |
|------------|------|--------|---------------|
| 2A: Bug fix | Cross-cutting | Tie | 1.0x |
| 2B: Feature mod | Logic change | **Phlex** | 0.62x |
| 2C: UI enhancement | UI heavy | **Vanilla** | 0.49x |

**Findings:**

1. **Co-location wins for logic changes** (2B) - When modifying business rules that affect multiple layers (model, controller, view), having views inline reduces context switching.

2. **ERB wins for UI-heavy features** (2C) - The Phlex Ruby DSL is ~2x more verbose than ERB for the same HTML output. For features that are primarily about adding UI elements, this verbosity hurts.

3. **No difference for cross-cutting concerns** (2A) - When the fix requires touching files outside the co-located controller (JavaScript, layouts), the benefit disappears.

**Recommendation:** The ideal architecture may be a hybrid - use Phlex for components with complex logic, ERB for simple templates with lots of markup.

## Running the Apps

```bash
# Vanilla
cd vanilla
bin/setup
bin/rails server -p 3001

# Phlex
cd phlex
bin/setup
bin/rails server -p 3002
```

## Architectural Differences

### Vanilla (Traditional)

```
app/
├── controllers/
│   └── comments_controller.rb      # Controller actions
├── views/
│   └── comments/
│       ├── _comment.html.erb       # Partial
│       ├── _form.html.erb          # Form partial
│       ├── _replies.html.erb       # Nested partial
│       └── index.html.erb          # Template
├── javascript/
│   └── controllers/
│       ├── comments_controller.js  # Stimulus
│       └── collapse_controller.js  # Stimulus
```

### Phlex (Co-located)

```
app/
├── controllers/
│   └── comments_controller.rb      # Controller + Views + Components
├── views/
│   └── base.rb                     # Base view class
```

One file contains:
- Controller actions
- View classes (Index, Show, New, Edit)
- Component classes (CommentThread, ReplyForm)
- Inline JavaScript for simple interactions

## Key Patterns

### Vanilla: Custom Routes

```ruby
resources :comments do
  member do
    post :approve
    post :reject
    post :collapse
    post :expand
  end
end
```

### Phlex: Resources

```ruby
resources :comments do
  resource :approval, only: [:create, :destroy]
  resource :collapse, only: [:create, :destroy]
  resources :replies, only: [:new, :create]
end
```

### Vanilla: Stimulus Controller

```javascript
// collapse_controller.js
export default class extends Controller {
  static targets = ["content", "button"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    this.buttonTarget.textContent =
      this.contentTarget.classList.contains("hidden") ? "Expand" : "Collapse"
  }
}
```

### Phlex: Inline JS

```ruby
button(
  onclick: safe("this.nextElementSibling.classList.toggle('hidden'); this.textContent = this.textContent === 'Expand' ? 'Collapse' : 'Expand'")
) { "Collapse" }
```

## Reproduce This Experiment

1. Clone this repo
2. Check out the `baseline` tag (both apps ready, no threaded comments)
3. Start fresh Claude session
4. Run the prompt below for each app
5. Measure results

### Prompt

```
Add threaded comments to this Rails app.

Requirements:
1. Comments can reply to other comments (use parent_id, max 3 levels)
2. Display comments in nested tree structure
3. "Reply" button shows inline reply form
4. Collapse/expand button for threads with replies
5. Delete requires confirmation (type comment excerpt), cascades to children
6. Approve/reject moderation (pending comments not shown to non-admins)
7. Add tests for all functionality

Follow existing patterns in the codebase. Do not ask clarifying questions.
```

---

## Iterative Development Experiments

The greenfield experiment showed no significant difference. The real test is **modifying existing code** where co-location should reduce context-gathering overhead.

### Iterative Experiment Design

Each experiment:
1. Start fresh AI session (no prior context)
2. Give identical prompts to both apps
3. Measure: files read, tool calls, tokens, time to completion

### Experiment 2A: Bug Fix

**Scenario:** User reports that deleting a parent comment doesn't properly cascade to children in the UI (children remain visible until page refresh).

**Prompt:**
```
Bug report: When deleting a comment with replies, the replies remain visible
until the page is refreshed. They should disappear immediately.

Fix this bug. Add a test to prevent regression.
```

**Hypothesis:** Phlex wins because:
- Fix requires understanding view rendering + delete action
- Vanilla: read controller + view + stimulus + routes
- Phlex: read posts_controller.rb (contains all context)

### Experiment 2B: Feature Modification

**Scenario:** Change moderation workflow - pending comments should show to their author (not just admins).

**Prompt:**
```
Change the comment visibility rules:
- Approved comments: visible to everyone
- Pending comments: visible to admins AND the comment author
- Rejected comments: visible only to admins

Update tests accordingly.
```

**Hypothesis:** Phlex wins because:
- Requires understanding: model scopes + view conditionals + controller filtering
- Vanilla: scattered across model, controller, view partial
- Phlex: model + posts_controller.rb (views inline)

### Experiment 2C: UI Enhancement

**Scenario:** Add "edit comment" functionality to existing comments.

**Prompt:**
```
Add the ability to edit comments:
- "Edit" button appears next to delete button
- Clicking edit shows inline form (like reply form)
- Only comment author can edit (and admins)
- Edited comments show "(edited)" timestamp
- Add tests

Follow existing patterns.
```

**Hypothesis:** Phlex wins because:
- Must understand existing patterns (reply form, permissions, UI structure)
- Vanilla: read multiple view partials, stimulus controller, routes
- Phlex: read one file to understand patterns, modify same file

### Experiment 2D: Performance Investigation

**Scenario:** Comments page is slow. Investigate and fix N+1 queries.

**Prompt:**
```
The posts show page is slow when there are many comments.
Profile the page, identify N+1 queries, and fix them.
Show before/after query counts.
```

**Hypothesis:** Mixed results expected
- N+1 detection requires model understanding (both similar)
- Fix location depends on where eager loading is applied
- May test whether co-location helps or hurts for db-layer work

### Measurement Template (Iterative)

```
Experiment: [2A/2B/2C/2D]
App: [vanilla/phlex]

Files read before first edit: [N]
Total files read: [N]
Total files modified: [N]
Lines changed: [N]

Tool calls:
  Read: [N]
  Edit: [N]
  Bash: [N]

Tokens: [N]

Time to first edit: [X min]
Time to completion: [X min]
Test runs: [N]
```

### Running Iterative Experiments

```bash
# Tag current state (post-greenfield)
git tag post-greenfield

# For each experiment:
# 1. Create branch: git checkout -b experiment-2a-vanilla
# 2. Start fresh Claude session
# 3. Run prompt
# 4. Record measurements
# 5. Repeat for phlex
```
