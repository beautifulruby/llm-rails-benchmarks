require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "should require body" do
    comment = Comment.new(user: users(:one), post: posts(:one))
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "should have valid status" do
    comment = Comment.new(body: "Test", user: users(:one), post: posts(:one), status: "invalid")
    assert_not comment.valid?
    assert_includes comment.errors[:status], "is not included in the list"
  end

  test "should default to pending status" do
    comment = Comment.create!(body: "Test", user: users(:one), post: posts(:one))
    assert_equal "pending", comment.status
  end

  test "should belong to user and post" do
    comment = comments(:root_comment)
    assert_equal users(:one), comment.user
    assert_equal posts(:one), comment.post
  end

  test "should have optional parent" do
    comment = comments(:root_comment)
    assert_nil comment.parent

    reply = comments(:reply_level_1)
    assert_equal comments(:root_comment), reply.parent
  end

  test "should have many replies" do
    comment = comments(:root_comment)
    assert_includes comment.replies, comments(:reply_level_1)
  end

  test "should calculate depth correctly" do
    assert_equal 0, comments(:root_comment).depth
    assert_equal 1, comments(:reply_level_1).depth
    assert_equal 2, comments(:reply_level_2).depth
  end

  test "should not allow nesting beyond 3 levels" do
    level_2 = comments(:reply_level_2)

    # Level 2 has depth 2, so trying to add a child would be depth 3 (not allowed)
    level_3 = Comment.new(body: "Level 3", user: users(:one), post: posts(:one), parent: level_2, status: "pending")

    assert_not level_3.valid?, "Level 3 should not be valid (depth would be 3)"
    assert_includes level_3.errors[:parent_id], "cannot nest more than 3 levels deep"
  end

  test "should cascade delete to children" do
    root = comments(:root_comment)
    reply_id = comments(:reply_level_1).id
    reply_count = root.replies.count

    assert reply_count > 0, "Root comment should have replies"

    root.destroy
    assert_not Comment.exists?(reply_id)
  end

  test "approved scope should only return approved comments" do
    approved_comments = Comment.approved
    assert_includes approved_comments, comments(:root_comment)
    assert_not_includes approved_comments, comments(:pending_comment)
    assert_not_includes approved_comments, comments(:rejected_comment)
  end

  test "pending scope should only return pending comments" do
    pending_comments = Comment.pending
    assert_includes pending_comments, comments(:pending_comment)
    assert_not_includes pending_comments, comments(:root_comment)
    assert_not_includes pending_comments, comments(:rejected_comment)
  end

  test "rejected scope should only return rejected comments" do
    rejected_comments = Comment.rejected
    assert_includes rejected_comments, comments(:rejected_comment)
    assert_not_includes rejected_comments, comments(:root_comment)
    assert_not_includes rejected_comments, comments(:pending_comment)
  end

  test "root_comments scope should only return comments without parent" do
    root_comments = Comment.root_comments
    assert_includes root_comments, comments(:root_comment)
    assert_not_includes root_comments, comments(:reply_level_1)
  end

  test "excerpt should truncate body" do
    comment = Comment.new(body: "A" * 100)
    excerpt = comment.excerpt(50)
    assert excerpt.length <= 53 # 50 + "..."
    assert excerpt.include?("...")
  end

  test "excerpt should not truncate short body" do
    comment = Comment.new(body: "Short")
    excerpt = comment.excerpt(50)
    assert_equal "Short", excerpt
  end

  test "approved comments should be visible to everyone" do
    comment = comments(:root_comment) # approved
    assert comment.visible_to?(nil, is_admin: false)
    assert comment.visible_to?(users(:one), is_admin: false)
    assert comment.visible_to?(users(:two), is_admin: false)
    assert comment.visible_to?(users(:one), is_admin: true)
  end

  test "pending comments should be visible to admin and author only" do
    comment = comments(:pending_comment) # pending, user: two

    # Not visible to non-admin non-author
    assert_not comment.visible_to?(nil, is_admin: false)
    assert_not comment.visible_to?(users(:one), is_admin: false)

    # Visible to author
    assert comment.visible_to?(users(:two), is_admin: false)

    # Visible to admin
    assert comment.visible_to?(users(:one), is_admin: true)
  end

  test "rejected comments should be visible to admin only" do
    comment = comments(:rejected_comment) # rejected, user: two

    # Not visible to non-admin (even author)
    assert_not comment.visible_to?(nil, is_admin: false)
    assert_not comment.visible_to?(users(:two), is_admin: false)
    assert_not comment.visible_to?(users(:one), is_admin: false)

    # Visible to admin
    assert comment.visible_to?(users(:one), is_admin: true)
  end

  test "visible_to scope returns all comments for admin" do
    visible = Comment.visible_to(users(:one), is_admin: true)
    assert_equal Comment.count, visible.count
  end

  test "visible_to scope returns approved comments for non-logged-in users" do
    visible = Comment.visible_to(nil, is_admin: false)
    assert_equal Comment.approved.count, visible.count
    assert_includes visible, comments(:root_comment)
    assert_not_includes visible, comments(:pending_comment)
    assert_not_includes visible, comments(:rejected_comment)
  end

  test "visible_to scope returns approved and own pending comments for logged-in users" do
    visible = Comment.visible_to(users(:two), is_admin: false)

    # Should include all approved comments
    assert_includes visible, comments(:root_comment)
    assert_includes visible, comments(:reply_level_1)

    # Should include own pending comment
    assert_includes visible, comments(:pending_comment)

    # Should NOT include rejected comment (even though it's user two's)
    assert_not_includes visible, comments(:rejected_comment)
  end
end
