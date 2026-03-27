# Threaded Comments Implementation

This Rails application now includes a fully-featured threaded comment system with moderation capabilities.

## Features Implemented

### 1. Threaded Comments with Nesting Limit
- Comments can reply to other comments using the `parent_id` field
- Maximum nesting depth of 3 levels (enforced via model validation)
- The `depth` method calculates the nesting level of any comment
- Root comments have `parent_id: nil`

### 2. Nested Tree Display
- Comments are displayed in a hierarchical tree structure
- Visual indentation (margin-left) for nested replies
- Border-left visual indicator for thread relationships
- Recursive rendering using the `_comment.html.erb` partial

### 3. Inline Reply Forms
- "Reply" button on each comment (shown only for comments at depth < 2)
- Clicking "Reply" shows an inline reply form using JavaScript (`toggleReplyForm`)
- Reply forms are hidden by default to keep the UI clean
- Parent ID is automatically set via a hidden field

### 4. Collapse/Expand Threads
- Threads with replies use HTML5 `<details>` and `<summary>` elements
- Summary shows reply count (e.g., "2 replies")
- Clicking the summary toggles visibility of child comments
- Threads are expanded by default (`open` attribute)

### 5. Delete with Confirmation
- Delete button requires typing the comment excerpt (first 30 characters)
- JavaScript prompt (`confirmDelete`) validates the typed text
- Confirmation text is submitted via a hidden form
- Cascading delete: deleting a parent comment also deletes all replies (via `dependent: :destroy`)

### 6. Moderation System
- Three moderation statuses: `pending`, `approved`, `rejected`
- New comments default to `pending` status
- Admins see all comments regardless of status
- Non-admin users only see `approved` comments
- Visual indicators: yellow border for pending, badges for status

### 7. Admin Controls
- Admin users have an `admin: true` boolean flag
- Approve/Reject buttons appear for pending comments (admins only)
- Approve and Reject actions use PATCH requests to dedicated endpoints
- Status changes redirect back to the post page

## Database Schema

### Users Table
```ruby
create_table "users" do |t|
  t.string "name"
  t.string "email"
  t.boolean "admin", default: false, null: false
  t.timestamps
end
```

### Comments Table
```ruby
create_table "comments" do |t|
  t.text "body"
  t.bigint "user_id", null: false
  t.bigint "post_id", null: false
  t.bigint "parent_id"
  t.string "moderation_status", default: "pending", null: false
  t.timestamps
end

add_index "comments", ["parent_id"]
add_index "comments", ["post_id"]
add_index "comments", ["user_id"]
add_index "comments", ["moderation_status"]
add_foreign_key "comments", "comments", column: "parent_id"
add_foreign_key "comments", "posts"
add_foreign_key "comments", "users"
```

## Routes

```ruby
resources :posts do
  resources :comments, only: [:create, :destroy] do
    member do
      patch :approve
      patch :reject
    end
  end
end
```

## Model Structure

### Comment Model
- **Associations:**
  - `belongs_to :user`
  - `belongs_to :post`
  - `belongs_to :parent, class_name: "Comment", optional: true`
  - `has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy`

- **Validations:**
  - `validates :body, presence: true`
  - `validates :moderation_status, inclusion: { in: %w[pending approved rejected] }`
  - `validate :maximum_nesting_depth` (custom validation for 3-level limit)

- **Scopes:**
  - `approved` - returns only approved comments
  - `pending` - returns only pending comments
  - `rejected` - returns only rejected comments
  - `root_comments` - returns comments with `parent_id: nil`

- **Instance Methods:**
  - `depth` - calculates nesting level (0 for root, 1 for first reply, etc.)
  - `excerpt(length = 50)` - truncates body for delete confirmation
  - `approve!` - sets status to "approved"
  - `reject!` - sets status to "rejected"
  - `pending?`, `approved?`, `rejected?` - status predicates

### User Model
- **Instance Methods:**
  - `admin?` - returns true if user is an admin

## Controllers

### CommentsController
- **Actions:**
  - `create` - creates a new comment, handles parent_id for threading
  - `destroy` - deletes comment if confirmation matches excerpt
  - `approve` - sets comment status to approved (admin only)
  - `reject` - sets comment status to rejected (admin only)

### PostsController
- **show action:**
  - Loads root comments only (using `root_comments` scope)
  - Filters to approved comments for non-admin users
  - Includes user and replies associations for N+1 prevention

### ApplicationController
- **Helper Methods:**
  - `current_user` - returns demo user (in production, integrate with authentication)

## JavaScript

### /app/javascript/comments.js
- `toggleReplyForm(commentId)` - shows/hides inline reply form
- `confirmDelete(commentId, excerpt)` - prompts for confirmation and submits delete form

## Views

### _comment.html.erb
- Recursively renders comment and all its replies
- Shows moderation status badges for pending/rejected comments
- Approve/Reject buttons for admins on pending comments
- Reply button (hidden at max depth)
- Collapse/expand using `<details>` element
- Visual indicators (border, indentation, badges)

### _comment_form.html.erb
- Simple form with textarea and submit button
- Hidden field for `parent_id` when replying
- Used for both root comments and replies

## Tests

### Model Tests (test/models/comment_test.rb)
- ✓ Valid comment creation
- ✓ Body presence validation
- ✓ Default moderation status is pending
- ✓ Moderation status validation
- ✓ Depth calculation (0, 1, 2 levels)
- ✓ Maximum depth validation (rejects depth 3)
- ✓ Excerpt truncation
- ✓ Approve/reject status changes
- ✓ Scopes (approved, pending, rejected, root_comments)
- ✓ Cascading delete of replies

### Controller Tests (test/controllers/comments_controller_test.rb)
- ✓ Create comment
- ✓ Create nested comment
- ✓ Prevent creation at depth 3
- ✓ Destroy with correct confirmation
- ✓ Prevent destroy with incorrect confirmation
- ✓ Cascading destroy of replies
- ✓ Approve comment
- ✓ Reject comment

### Integration Tests (test/integration/comment_visibility_test.rb)
- ✓ Regular users only see approved comments
- ✓ Admins see all comments
- ✓ Approved nested comments are visible
- ✓ Pending/rejected nested comments are hidden
- ✓ Reply count only includes approved comments

## Seed Data

The seed file creates:
- 3 users (Alice as admin, Bob and Charlie as regular users)
- 3 blog posts
- 9 threaded comments demonstrating various nesting levels and moderation statuses

To reset and seed the database:
```bash
bin/rails db:reset
```

## Usage Examples

### Creating a Root Comment
```ruby
Comment.create!(
  body: "This is a top-level comment",
  user: user,
  post: post,
  parent: nil,
  moderation_status: "pending"
)
```

### Creating a Reply
```ruby
parent_comment = Comment.find(1)
Comment.create!(
  body: "This is a reply",
  user: user,
  post: post,
  parent: parent_comment,
  moderation_status: "pending"
)
```

### Approving/Rejecting Comments
```ruby
comment.approve!  # Sets moderation_status to "approved"
comment.reject!   # Sets moderation_status to "rejected"
```

### Querying Comments
```ruby
# Get all approved root comments for a post
post.comments.root_comments.approved

# Get all replies to a comment
comment.replies

# Check comment depth
comment.depth  # Returns 0, 1, or 2
```

## Future Enhancements

Potential improvements for production use:
1. Real authentication system (replace demo user)
2. Email notifications for replies
3. Edit comment functionality
4. Markdown/rich text support
5. Reaction counts (upvotes/downvotes)
6. Report/flag functionality
7. Admin dashboard for bulk moderation
8. Rate limiting for comment creation
9. Spam detection integration
10. Soft delete with archival
