require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: "Test User", email: "test@example.com")
    @post = Post.create!(title: "Test Post", body: "Test body", user: @user)
  end

  test "valid comment" do
    comment = Comment.new(body: "Test comment", user: @user, post: @post)
    assert comment.valid?
  end

  test "requires body" do
    comment = Comment.new(user: @user, post: @post)
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "default moderation status is pending" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    assert_equal "pending", comment.moderation_status
  end

  test "moderation status must be valid" do
    comment = Comment.new(body: "Test", user: @user, post: @post, moderation_status: "invalid")
    assert_not comment.valid?
    assert_includes comment.errors[:moderation_status], "is not included in the list"
  end

  test "depth returns 0 for root comment" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    assert_equal 0, comment.depth
  end

  test "depth returns 1 for first level reply" do
    parent = Comment.create!(body: "Parent", user: @user, post: @post)
    reply = Comment.create!(body: "Reply", user: @user, post: @post, parent: parent)
    assert_equal 1, reply.depth
  end

  test "depth returns 2 for second level reply" do
    parent = Comment.create!(body: "Parent", user: @user, post: @post)
    reply1 = Comment.create!(body: "Reply 1", user: @user, post: @post, parent: parent)
    reply2 = Comment.create!(body: "Reply 2", user: @user, post: @post, parent: reply1)
    assert_equal 2, reply2.depth
  end

  test "cannot create comment at depth 3" do
    parent = Comment.create!(body: "Parent", user: @user, post: @post)
    reply1 = Comment.create!(body: "Reply 1", user: @user, post: @post, parent: parent)
    reply2 = Comment.create!(body: "Reply 2", user: @user, post: @post, parent: reply1)
    reply3 = Comment.new(body: "Reply 3", user: @user, post: @post, parent: reply2)

    assert_not reply3.valid?
    assert_includes reply3.errors[:parent_id], "comments can only be nested 3 levels deep"
  end

  test "excerpt truncates long text" do
    comment = Comment.create!(body: "A" * 100, user: @user, post: @post)
    assert_equal 50, comment.excerpt.length
    assert comment.excerpt.ends_with?("...")
  end

  test "excerpt does not truncate short text" do
    comment = Comment.create!(body: "Short", user: @user, post: @post)
    assert_equal "Short", comment.excerpt
  end

  test "approve! changes status to approved" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    comment.approve!
    assert comment.approved?
  end

  test "reject! changes status to rejected" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    comment.reject!
    assert comment.rejected?
  end

  test "pending? returns true for pending comments" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    assert comment.pending?
  end

  test "approved scope returns only approved comments" do
    Comment.delete_all  # Clear fixtures
    approved = Comment.create!(body: "Approved", user: @user, post: @post, moderation_status: "approved")
    Comment.create!(body: "Pending", user: @user, post: @post, moderation_status: "pending")
    Comment.create!(body: "Rejected", user: @user, post: @post, moderation_status: "rejected")

    assert_equal [approved], Comment.approved.to_a
  end

  test "pending scope returns only pending comments" do
    Comment.delete_all  # Clear fixtures
    Comment.create!(body: "Approved", user: @user, post: @post, moderation_status: "approved")
    pending = Comment.create!(body: "Pending", user: @user, post: @post, moderation_status: "pending")
    Comment.create!(body: "Rejected", user: @user, post: @post, moderation_status: "rejected")

    assert_equal [pending], Comment.pending.to_a
  end

  test "rejected scope returns only rejected comments" do
    Comment.delete_all  # Clear fixtures
    Comment.create!(body: "Approved", user: @user, post: @post, moderation_status: "approved")
    Comment.create!(body: "Pending", user: @user, post: @post, moderation_status: "pending")
    rejected = Comment.create!(body: "Rejected", user: @user, post: @post, moderation_status: "rejected")

    assert_equal [rejected], Comment.rejected.to_a
  end

  test "root_comments scope returns only root comments" do
    Comment.delete_all  # Clear fixtures
    root1 = Comment.create!(body: "Root 1", user: @user, post: @post)
    root2 = Comment.create!(body: "Root 2", user: @user, post: @post)
    Comment.create!(body: "Reply", user: @user, post: @post, parent: root1)

    assert_equal 2, Comment.root_comments.count
    assert_includes Comment.root_comments, root1
    assert_includes Comment.root_comments, root2
  end

  test "destroying parent destroys replies" do
    parent = Comment.create!(body: "Parent", user: @user, post: @post)
    reply = Comment.create!(body: "Reply", user: @user, post: @post, parent: parent)

    assert_difference "Comment.count", -2 do
      parent.destroy
    end
  end

  test "replies association returns child comments" do
    parent = Comment.create!(body: "Parent", user: @user, post: @post)
    reply1 = Comment.create!(body: "Reply 1", user: @user, post: @post, parent: parent)
    reply2 = Comment.create!(body: "Reply 2", user: @user, post: @post, parent: parent)

    assert_equal 2, parent.replies.count
    assert_includes parent.replies, reply1
    assert_includes parent.replies, reply2
  end

  test "visible_to? returns true for approved comments to anyone" do
    comment = Comment.create!(body: "Test", user: @user, post: @post, moderation_status: "approved")
    other_user = User.create!(name: "Other", email: "other@example.com")
    admin = User.create!(name: "Admin", email: "admin@example.com", admin: true)

    assert comment.visible_to?(nil)
    assert comment.visible_to?(@user)
    assert comment.visible_to?(other_user)
    assert comment.visible_to?(admin)
  end

  test "visible_to? returns true for pending comments to author and admin" do
    comment = Comment.create!(body: "Test", user: @user, post: @post, moderation_status: "pending")
    other_user = User.create!(name: "Other", email: "other@example.com")
    admin = User.create!(name: "Admin", email: "admin@example.com", admin: true)

    assert_not comment.visible_to?(nil)
    assert comment.visible_to?(@user) # author
    assert_not comment.visible_to?(other_user)
    assert comment.visible_to?(admin)
  end

  test "visible_to? returns true for rejected comments only to admin" do
    comment = Comment.create!(body: "Test", user: @user, post: @post, moderation_status: "rejected")
    other_user = User.create!(name: "Other", email: "other@example.com")
    admin = User.create!(name: "Admin", email: "admin@example.com", admin: true)

    assert_not comment.visible_to?(nil)
    assert_not comment.visible_to?(@user) # even the author
    assert_not comment.visible_to?(other_user)
    assert comment.visible_to?(admin)
  end

  test "visible_to scope returns all comments for admin" do
    Comment.delete_all
    approved = Comment.create!(body: "Approved", user: @user, post: @post, moderation_status: "approved")
    pending = Comment.create!(body: "Pending", user: @user, post: @post, moderation_status: "pending")
    rejected = Comment.create!(body: "Rejected", user: @user, post: @post, moderation_status: "rejected")
    admin = User.create!(name: "Admin", email: "admin@example.com", admin: true)

    visible = Comment.visible_to(admin)
    assert_equal 3, visible.count
    assert_includes visible, approved
    assert_includes visible, pending
    assert_includes visible, rejected
  end

  test "visible_to scope returns approved comments and own pending for regular user" do
    Comment.delete_all
    other_user = User.create!(name: "Other", email: "other@example.com")

    approved = Comment.create!(body: "Approved", user: @user, post: @post, moderation_status: "approved")
    pending_by_user = Comment.create!(body: "Pending by user", user: @user, post: @post, moderation_status: "pending")
    pending_by_other = Comment.create!(body: "Pending by other", user: other_user, post: @post, moderation_status: "pending")
    rejected = Comment.create!(body: "Rejected", user: @user, post: @post, moderation_status: "rejected")

    visible = Comment.visible_to(@user)
    assert_equal 2, visible.count
    assert_includes visible, approved
    assert_includes visible, pending_by_user
    assert_not_includes visible, pending_by_other
    assert_not_includes visible, rejected
  end

  test "visible_to scope returns only approved comments for nil user" do
    Comment.delete_all
    approved = Comment.create!(body: "Approved", user: @user, post: @post, moderation_status: "approved")
    pending = Comment.create!(body: "Pending", user: @user, post: @post, moderation_status: "pending")
    rejected = Comment.create!(body: "Rejected", user: @user, post: @post, moderation_status: "rejected")

    visible = Comment.visible_to(nil)
    assert_equal 1, visible.count
    assert_includes visible, approved
    assert_not_includes visible, pending
    assert_not_includes visible, rejected
  end

  test "edited? returns false for new comment" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    assert_not comment.edited?
  end

  test "edited? returns true when edited_at is set" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    comment.update!(edited_at: Time.current)
    assert comment.edited?
  end

  test "editable_by? returns true for comment author" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    assert comment.editable_by?(@user)
  end

  test "editable_by? returns true for admin" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    admin = User.create!(name: "Admin", email: "admin@example.com", admin: true)
    assert comment.editable_by?(admin)
  end

  test "editable_by? returns false for other users" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    other_user = User.create!(name: "Other", email: "other@example.com")
    assert_not comment.editable_by?(other_user)
  end

  test "editable_by? returns false for nil user" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)
    assert_not comment.editable_by?(nil)
  end
end
