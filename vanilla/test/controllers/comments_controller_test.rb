require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Test User", email: "test@example.com")
    @admin = User.create!(name: "Admin User", email: "admin@example.com", admin: true)
    @post = Post.create!(title: "Test Post", body: "Test body", user: @user)
  end

  test "should create comment" do
    assert_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { body: "Test comment" } }
    end

    assert_redirected_to post_path(@post)
    assert_equal "pending", Comment.last.moderation_status
  end

  test "should not create comment without body" do
    assert_no_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { body: "" } }
    end

    assert_redirected_to post_path(@post)
  end

  test "should create nested comment" do
    parent = Comment.create!(body: "Parent", user: @user, post: @post)

    assert_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { body: "Reply", parent_id: parent.id } }
    end

    reply = Comment.last
    assert_equal parent, reply.parent
  end

  test "should not create comment at depth 3" do
    parent = Comment.create!(body: "Parent", user: @user, post: @post)
    reply1 = Comment.create!(body: "Reply 1", user: @user, post: @post, parent: parent)
    reply2 = Comment.create!(body: "Reply 2", user: @user, post: @post, parent: reply1)

    assert_no_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { body: "Reply 3", parent_id: reply2.id } }
    end
  end

  test "should destroy comment with correct confirmation" do
    comment = Comment.create!(body: "Test comment to delete", user: @user, post: @post)
    excerpt = comment.excerpt(30)

    assert_difference("Comment.count", -1) do
      delete post_comment_url(@post, comment), params: { confirmation: excerpt }
    end

    assert_redirected_to post_path(@post)
  end

  test "should not destroy comment with incorrect confirmation" do
    comment = Comment.create!(body: "Test comment", user: @user, post: @post)

    assert_no_difference("Comment.count") do
      delete post_comment_url(@post, comment), params: { confirmation: "wrong text" }
    end

    assert_redirected_to post_path(@post)
  end

  test "should destroy comment and its replies" do
    parent = Comment.create!(body: "Parent", user: @user, post: @post)
    Comment.create!(body: "Reply", user: @user, post: @post, parent: parent)
    excerpt = parent.excerpt(30)

    assert_difference("Comment.count", -2) do
      delete post_comment_url(@post, parent), params: { confirmation: excerpt }
    end
  end

  test "should approve comment" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)

    patch approve_post_comment_url(@post, comment)

    assert_redirected_to post_path(@post)
    assert comment.reload.approved?
  end

  test "should reject comment" do
    comment = Comment.create!(body: "Test", user: @user, post: @post)

    patch reject_post_comment_url(@post, comment)

    assert_redirected_to post_path(@post)
    assert comment.reload.rejected?
  end

  test "should remove comment from DOM immediately via turbo stream" do
    parent = Comment.create!(body: "Parent comment", user: @user, post: @post)
    reply1 = Comment.create!(body: "Reply 1", user: @user, post: @post, parent: parent)
    reply2 = Comment.create!(body: "Reply 2", user: @user, post: @post, parent: parent)
    excerpt = parent.excerpt(30)

    delete post_comment_url(@post, parent),
           params: { confirmation: excerpt },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_match /turbo-stream.*action="remove".*target="comment-#{parent.id}"/, response.body

    # Verify cascade deletion
    assert_not Comment.exists?(parent.id)
    assert_not Comment.exists?(reply1.id)
    assert_not Comment.exists?(reply2.id)
  end

  test "should update comment by author" do
    # current_user in tests is User.first (created by first_or_create in ApplicationController)
    comment_author = User.first_or_create!(name: "Demo User", email: "demo@example.com")
    comment = Comment.create!(body: "Original text", user: comment_author, post: @post)

    patch post_comment_url(@post, comment), params: { comment: { body: "Updated text" } }

    assert_redirected_to post_path(@post)
    comment.reload
    assert_equal "Updated text", comment.body
    assert_not_nil comment.edited_at
  end

  test "should update comment by admin" do
    # Make sure current_user (Demo User) is an admin
    demo_user = User.first_or_create!(name: "Demo User", email: "demo@example.com")
    demo_user.update!(admin: true)

    comment = Comment.create!(body: "Original text", user: @user, post: @post)

    patch post_comment_url(@post, comment), params: { comment: { body: "Admin updated" } }

    assert_redirected_to post_path(@post)
    comment.reload
    assert_equal "Admin updated", comment.body
    assert_not_nil comment.edited_at
  end

  test "should not update comment without body" do
    comment = Comment.create!(body: "Original text", user: @user, post: @post)

    patch post_comment_url(@post, comment), params: { comment: { body: "" } }

    assert_redirected_to post_path(@post)
    comment.reload
    assert_equal "Original text", comment.body
  end
end
