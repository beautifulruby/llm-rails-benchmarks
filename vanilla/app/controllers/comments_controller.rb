class CommentsController < ApplicationController
  before_action :set_post
  before_action :set_comment, only: [:update, :destroy, :approve, :reject]
  before_action :authorize_edit, only: [:update]

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @post, notice: "Comment was successfully added."
    else
      redirect_to @post, alert: "Failed to add comment: #{@comment.errors.full_messages.join(', ')}"
    end
  end

  def update
    @comment.edited_at = Time.current
    if @comment.update(comment_params)
      redirect_to @post, notice: "Comment was successfully updated."
    else
      redirect_to @post, alert: "Failed to update comment: #{@comment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    if params[:confirmation] == @comment.excerpt(30)
      comment_id = @comment.id
      @comment.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove("comment-#{comment_id}") }
        format.html { redirect_to @post, notice: "Comment was successfully deleted." }
      end
    else
      redirect_to @post, alert: "Confirmation text did not match. Comment was not deleted."
    end
  end

  def approve
    @comment.approve!
    redirect_to @post, notice: "Comment was approved."
  end

  def reject
    @comment.reject!
    redirect_to @post, notice: "Comment was rejected."
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def authorize_edit
    unless @comment.editable_by?(current_user)
      redirect_to @post, alert: "You are not authorized to edit this comment."
    end
  end

  def comment_params
    params.require(:comment).permit(:body, :parent_id)
  end
end
