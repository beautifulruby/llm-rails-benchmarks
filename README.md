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

### Vanilla Rails

```
Started: [timestamp]
Finished: [timestamp]
Duration: [X minutes]

Files created: [N]
Files modified: [N]
Lines added: [N]

Tool calls:
  Read: [N]
  Edit: [N]
  Write: [N]
  Bash: [N]

Input tokens: [N]
Output tokens: [N]

Test runs: [N]
Failures before green: [N]
```

### Phlex Rails

```
Started: [timestamp]
Finished: [timestamp]
Duration: [X minutes]

Files created: [N]
Files modified: [N]
Lines added: [N]

Tool calls:
  Read: [N]
  Edit: [N]
  Write: [N]
  Bash: [N]

Input tokens: [N]
Output tokens: [N]

Test runs: [N]
Failures before green: [N]
```

### Comparison

| Metric | Vanilla | Phlex | Ratio |
|--------|---------|-------|-------|
| Duration | | | |
| Files touched | | | |
| Lines of code | | | |
| Input tokens | | | |
| Tool calls | | | |

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
