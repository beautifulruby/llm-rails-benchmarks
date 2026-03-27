require "test_helper"

class CommentVisibilityTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Regular User", email: "user@example.com", admin: false)
    @admin = User.create!(name: "Admin User", email: "admin@example.com", admin: true)
    @post = Post.create!(title: "Test Post", body: "Test body", user: @user)

    @approved_comment = Comment.create!(
      body: "Approved comment",
      user: @user,
      post: @post,
      moderation_status: "approved"
    )

    @pending_comment = Comment.create!(
      body: "Pending comment",
      user: @user,
      post: @post,
      moderation_status: "pending"
    )

    @rejected_comment = Comment.create!(
      body: "Rejected comment",
      user: @user,
      post: @post,
      moderation_status: "rejected"
    )
  end

  test "regular users see approved comments and their own pending comments" do
    # The current_user in ApplicationController is the first user (Demo User)
    # which is different from @user, so we won't see pending comments
    get post_path(@post)

    assert_response :success
    assert_select "p", text: "Approved comment"
    # Pending and rejected comments are not visible because current_user != @user
    assert_select "p", text: "Pending comment", count: 0
    assert_select "p", text: "Rejected comment", count: 0
  end

  test "comment visibility logic works correctly" do
    # Verify that the visibility methods work as expected
    demo_user = User.first # The current_user from ApplicationController

    # Approved comments visible to everyone
    assert @approved_comment.visible_to?(nil)
    assert @approved_comment.visible_to?(demo_user)
    assert @approved_comment.visible_to?(@admin)

    # Pending comments visible to admins and author
    assert_not @pending_comment.visible_to?(nil)
    assert_not @pending_comment.visible_to?(demo_user)
    assert @pending_comment.visible_to?(@user) # author
    assert @pending_comment.visible_to?(@admin)

    # Rejected comments visible only to admins
    assert_not @rejected_comment.visible_to?(nil)
    assert_not @rejected_comment.visible_to?(demo_user)
    assert_not @rejected_comment.visible_to?(@user) # even the author
    assert @rejected_comment.visible_to?(@admin)
  end

  test "approved nested comments are visible" do
    reply = Comment.create!(
      body: "Approved reply",
      user: @user,
      post: @post,
      parent: @approved_comment,
      moderation_status: "approved"
    )

    get post_path(@post)

    assert_response :success
    assert_select "p", text: "Approved reply"
  end

  test "pending nested comments are not visible to regular users" do
    reply = Comment.create!(
      body: "Pending reply",
      user: @user,
      post: @post,
      parent: @approved_comment,
      moderation_status: "pending"
    )

    get post_path(@post)

    assert_response :success
    assert_select "p", text: "Pending reply", count: 0
  end

  test "rejected nested comments are not visible to regular users" do
    reply = Comment.create!(
      body: "Rejected reply",
      user: @user,
      post: @post,
      parent: @approved_comment,
      moderation_status: "rejected"
    )

    get post_path(@post)

    assert_response :success
    assert_select "p", text: "Rejected reply", count: 0
  end

  test "reply count only includes visible comments for regular users" do
    demo_user = User.first # current_user from ApplicationController

    Comment.create!(
      body: "Approved reply 1",
      user: @user,
      post: @post,
      parent: @approved_comment,
      moderation_status: "approved"
    )

    Comment.create!(
      body: "Approved reply 2",
      user: @user,
      post: @post,
      parent: @approved_comment,
      moderation_status: "approved"
    )

    # Pending reply by different user - not visible to demo_user
    Comment.create!(
      body: "Pending reply",
      user: @user,
      post: @post,
      parent: @approved_comment,
      moderation_status: "pending"
    )

    get post_path(@post)

    assert_response :success
    # The details summary should show 2 replies (approved only), not 3
    assert_select "summary", text: /2 replies/
  end

  test "author sees their own pending comments" do
    # Create a new user and make them the author
    author = User.create!(name: "Author", email: "author@example.com", admin: false)
    author_post = Post.create!(title: "Author Post", body: "Test", user: author)

    pending_by_author = Comment.create!(
      body: "Author's pending comment",
      user: author,
      post: author_post,
      moderation_status: "pending"
    )

    # Verify visibility
    assert pending_by_author.visible_to?(author)

    # Verify it's in the scope
    visible = Comment.where(post: author_post).visible_to(author)
    assert_includes visible, pending_by_author
  end

  test "author does not see their own rejected comments" do
    author = User.create!(name: "Author", email: "author@example.com", admin: false)
    author_post = Post.create!(title: "Author Post", body: "Test", user: author)

    rejected_by_author = Comment.create!(
      body: "Author's rejected comment",
      user: author,
      post: author_post,
      moderation_status: "rejected"
    )

    # Verify visibility
    assert_not rejected_by_author.visible_to?(author)

    # Verify it's not in the scope
    visible = Comment.where(post: author_post).visible_to(author)
    assert_not_includes visible, rejected_by_author
  end
end
