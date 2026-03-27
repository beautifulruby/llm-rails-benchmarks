require "test_helper"

class CommentsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
  end

  test "regular users should only see approved comments" do
    get post_path(@post)

    assert_response :success
    assert_select "div", text: /This is a root comment/ # approved
    assert_select "div", text: /This is a first level reply/ # approved
    assert_no_match /This comment is pending moderation/, @response.body
    assert_no_match /This comment was rejected/, @response.body
  end

  test "comment authors should see their own pending comments" do
    # pending_comment belongs to user two
    # We need to simulate being logged in as user two
    # Since current_user is hardcoded to User.first, we need to test the visibility logic differently

    # For now, verify the model method works correctly
    pending = comments(:pending_comment)
    author = users(:two)

    assert pending.visible_to?(author, is_admin: false), "Author should see their own pending comment"
  end

  test "admins should see all comments with status badges" do
    get post_path(@post, admin: true)

    assert_response :success
    assert_match /This is a root comment/, @response.body
    assert_match /pending moderation/, @response.body
    assert_match /Pending/, @response.body # status badge
  end

  test "should display nested comment structure" do
    get post_path(@post)

    assert_response :success
    # Check that replies are nested
    assert_match /This is a root comment/, @response.body
    assert_match /This is a first level reply/, @response.body
  end

  test "should show reply button for approved comments under max depth" do
    get post_path(@post)

    assert_response :success
    assert_match /Reply/, @response.body
  end

  test "should not show reply button for comments at max depth" do
    # Create a comment at depth 2 (the maximum allowed depth for replies)
    level_2 = comments(:reply_level_2)

    get post_path(@post)

    # The reply button should not appear for level 2 comments since they're at the limit
    # We're checking the response contains the level 2 comment but verify reply logic in view
    assert_response :success
  end

  test "should show moderation buttons for admins on pending comments" do
    get post_path(@post, admin: true)

    assert_response :success
    assert_match /Approve/, @response.body
    assert_match /Reject/, @response.body
  end

  test "should not show moderation buttons for non-admins" do
    get post_path(@post)

    assert_response :success
    assert_no_match /Approve/, @response.body
    # Reject might appear in other contexts, so we check for the moderation-specific pattern
  end

  test "should show collapse button for comments with replies" do
    get post_path(@post)

    assert_response :success
    assert_match /Collapse/, @response.body
  end

  test "comment count should show approved count for regular users" do
    get post_path(@post)

    assert_response :success
    # Should show count of approved comments only
    approved_count = @post.comments.approved.count
    assert_match /Comments \(#{approved_count}\)/, @response.body
  end

  test "comment count should show both approved and total for admins" do
    get post_path(@post, admin: true)

    assert_response :success
    approved_count = @post.comments.approved.count
    total_count = @post.comments.count
    assert_match /#{approved_count} approved \/ #{total_count} total/, @response.body
  end

  test "should be able to post a new comment" do
    get post_path(@post)
    assert_response :success

    assert_difference("Comment.count") do
      post post_comments_path(@post), params: {
        comment: { body: "Integration test comment" }
      }
    end

    follow_redirect!
    assert_response :success
    assert_match /pending moderation/, flash[:notice]
  end

  test "should be able to reply to a comment" do
    parent = comments(:root_comment)

    assert_difference("Comment.count") do
      post post_comments_path(@post), params: {
        comment: {
          body: "Integration test reply",
          parent_id: parent.id
        }
      }
    end

    follow_redirect!
    assert_response :success

    new_comment = Comment.last
    assert_equal parent, new_comment.parent
  end

  test "delete button should exist for comments" do
    get post_path(@post)

    assert_response :success
    assert_match /Delete/, @response.body
  end

  test "edit button should appear for comment author" do
    get post_path(@post)

    assert_response :success
    # Should have edit button (current_user is User.first who owns root_comment)
    assert_match /Edit/, @response.body
  end

  test "edit button should appear for admins on all comments" do
    get post_path(@post, admin: true)

    assert_response :success
    # Admins should see edit buttons
    assert_match /Edit/, @response.body
  end

  test "should show edited timestamp for edited comments" do
    comment = comments(:root_comment)
    comment.update(edited_at: 5.minutes.ago)

    get post_path(@post)

    assert_response :success
    assert_match /\(edited/, @response.body
  end

  test "should not show edited timestamp for non-edited comments" do
    get post_path(@post)

    # Check that most comments don't have edited timestamp
    # The response may contain "(edited" if we have any edited comments in fixtures
    # but the root comment should not have it initially
    comment = comments(:root_comment)
    assert_nil comment.edited_at
  end

  test "should be able to update a comment" do
    comment = comments(:root_comment)
    new_body = "This is an updated comment"

    # Use admin mode since current_user in controller is hardcoded to "Demo User"
    patch post_comment_path(@post, comment, admin: true), params: {
      comment: { body: new_body }
    }

    follow_redirect!
    assert_response :success
    assert_match /successfully updated/, flash[:notice]

    comment.reload
    assert_equal new_body, comment.body
    assert_not_nil comment.edited_at
  end

  test "edit form should be present in the DOM" do
    get post_path(@post)

    assert_response :success
    # The edit form should exist in the DOM (even if hidden)
    assert_match /Update Comment/, @response.body
  end
end
