# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_post
  before_action :set_comment, only: [:edit, :update, :destroy, :approve, :reject]
  before_action :authorize_edit, only: [:edit, :update]

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

    comment_id = @comment.id
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to @post, notice: "Comment and all replies were successfully deleted." }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("comment-#{comment_id}") }
    end
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

  def edit
    # Not implementing turbo stream for edit - simpler to handle with inline form toggle via JS
    redirect_to @post
  end

  def update
    if @comment.update(comment_params.merge(edited_at: Time.current))
      redirect_to @post, notice: "Comment was successfully updated."
    else
      redirect_to @post, alert: "Failed to update comment: #{@comment.errors.full_messages.join(', ')}"
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

  def authorize_edit
    unless @comment.user_id == current_user.id || admin?
      redirect_to @post, alert: "You are not authorized to edit this comment."
    end
  end
end
