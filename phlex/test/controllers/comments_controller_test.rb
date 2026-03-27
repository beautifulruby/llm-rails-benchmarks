require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @user = users(:one)
  end

  test "should create comment with pending status" do
    assert_difference("Comment.count") do
      post post_comments_path(@post), params: {
        comment: { body: "New comment" }
      }
    end

    new_comment = Comment.last
    assert_equal "pending", new_comment.status
    assert_redirected_to post_path(@post)
    assert_match /pending moderation/, flash[:notice]
  end

  test "should create nested comment" do
    parent = comments(:root_comment)

    assert_difference("Comment.count") do
      post post_comments_path(@post), params: {
        comment: { body: "Reply to comment", parent_id: parent.id }
      }
    end

    reply = Comment.last
    assert_equal parent, reply.parent
  end

  test "should not create comment beyond max depth" do
    # Create a chain to depth 2
    level_0 = comments(:root_comment)
    level_1 = comments(:reply_level_1)
    level_2 = comments(:reply_level_2)

    # Trying to add level 3 should fail validation
    assert_no_difference("Comment.count") do
      post post_comments_path(@post), params: {
        comment: { body: "Too deep", parent_id: level_2.id }
      }
    end

    assert_redirected_to post_path(@post)
    assert_match /cannot nest more than 3 levels deep/, flash[:alert]
  end

  test "should delete comment with correct excerpt" do
    comment = comments(:pending_comment)  # Use a comment without replies
    excerpt = comment.excerpt(50)

    assert_difference("Comment.count", -1) do
      delete post_comment_path(@post, comment), params: {
        comment_excerpt: excerpt
      }
    end

    assert_redirected_to post_path(@post)
    assert_match /successfully deleted/, flash[:notice]
  end

  test "should not delete comment with incorrect excerpt" do
    comment = comments(:root_comment)

    assert_no_difference("Comment.count") do
      delete post_comment_path(@post, comment), params: {
        comment_excerpt: "wrong excerpt"
      }
    end

    assert_redirected_to post_path(@post)
    assert_match /excerpt did not match/, flash[:alert]
  end

  test "should cascade delete replies" do
    root = comments(:root_comment)
    reply_level_1_id = comments(:reply_level_1).id
    reply_level_2_id = comments(:reply_level_2).id
    excerpt = root.excerpt(50)

    # Should delete root and all its descendants (reply_level_1 and reply_level_2)
    assert_difference("Comment.count", -3) do
      delete post_comment_path(@post, root), params: {
        comment_excerpt: excerpt
      }
    end

    assert_not Comment.exists?(reply_level_1_id)
    assert_not Comment.exists?(reply_level_2_id)
  end

  test "should approve pending comment" do
    comment = comments(:pending_comment)

    patch approve_post_comment_path(@post, comment)

    comment.reload
    assert_equal "approved", comment.status
    assert_redirected_to post_path(@post)
    assert_match /approved/, flash[:notice]
  end

  test "should reject pending comment" do
    comment = comments(:pending_comment)

    patch reject_post_comment_path(@post, comment)

    comment.reload
    assert_equal "rejected", comment.status
    assert_redirected_to post_path(@post)
    assert_match /rejected/, flash[:notice]
  end
end
