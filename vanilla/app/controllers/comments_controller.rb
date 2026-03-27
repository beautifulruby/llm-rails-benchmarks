class CommentsController < ApplicationController
  before_action :set_post
  before_action :set_comment, only: [:destroy, :approve, :reject]

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @post, notice: "Comment was successfully added."
    else
      redirect_to @post, alert: "Failed to add comment: #{@comment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    if params[:confirmation] == @comment.excerpt(30)
      @comment.destroy
      redirect_to @post, notice: "Comment was successfully deleted."
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

  def comment_params
    params.require(:comment).permit(:body, :parent_id)
  end
end
