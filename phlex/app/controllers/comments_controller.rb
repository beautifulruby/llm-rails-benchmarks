# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_post
  before_action :set_comment, only: [:destroy, :approve, :reject]

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user
    @comment.status = "pending"

    if @comment.save
      redirect_to @post, notice: "Comment was successfully added and is pending moderation."
    else
      redirect_to @post, alert: "Failed to add comment: #{@comment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    excerpt = params[:comment_excerpt]
    expected_excerpt = @comment.excerpt(50)

    if excerpt != expected_excerpt
      redirect_to @post, alert: "Deletion cancelled: excerpt did not match. Expected: '#{expected_excerpt}'"
      return
    end

    @comment.destroy
    redirect_to @post, notice: "Comment and all replies were successfully deleted."
  end

  def approve
    if @comment.update(status: "approved")
      redirect_to @post, notice: "Comment was approved."
    else
      redirect_to @post, alert: "Failed to approve comment."
    end
  end

  def reject
    if @comment.update(status: "rejected")
      redirect_to @post, notice: "Comment was rejected."
    else
      redirect_to @post, alert: "Failed to reject comment."
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body, :parent_id)
  end

  def current_user
    @current_user ||= User.first_or_create!(name: "Demo User", email: "demo@example.com")
  end

  def admin?
    # Simple admin check - in production, this would check actual user roles
    params[:admin] == "true" || session[:admin] == true
  end
  helper_method :admin?
end
