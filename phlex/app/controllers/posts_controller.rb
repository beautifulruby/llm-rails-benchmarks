# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  # ============================================================================
  # VIEWS - Co-located for maximum context efficiency
  # ============================================================================

  class IndexView < Views::Base
    def initialize(posts:)
      @posts = posts
    end

    def view_template
      div(class: "max-w-4xl mx-auto px-4 py-8") do
        div(class: "flex justify-between items-center mb-8") do
          h1(class: "text-3xl font-bold text-gray-900") { "Posts" }
          a(href: new_post_path, class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700") { "New Post" }
        end

        if @posts.any?
          div(class: "space-y-4") do
            @posts.each { |post| render PostCard.new(post:) }
          end
        else
          p(class: "text-gray-500") { "No posts yet. Create your first one!" }
        end
      end
    end
  end

  class PostCard < Views::Base
    def initialize(post:)
      @post = post
    end

    def view_template
      div(class: "border border-gray-200 rounded-lg p-4 hover:shadow-md transition") do
        a(href: post_path(@post)) do
          h2(class: "text-xl font-semibold text-gray-900 hover:text-blue-600") { @post.title }
        end
        p(class: "text-gray-600 mt-2") { @post.body.truncate(150) }
        div(class: "mt-4 text-sm text-gray-500") do
          plain "By #{@post.user.name} · #{view_context.time_ago_in_words(@post.created_at)} ago"
        end
      end
    end
  end

  class ShowView < Views::Base
    def initialize(post:, comments:, comment:)
      @post = post
      @comments = comments
      @comment = comment
    end

    def view_template
      div(class: "max-w-4xl mx-auto px-4 py-8") do
        div(class: "mb-6") do
          a(href: posts_path, class: "text-blue-600 hover:underline") { "← Back to posts" }
        end

        article(class: "mb-8") do
          h1(class: "text-3xl font-bold text-gray-900 mb-4") { @post.title }
          div(class: "text-sm text-gray-500 mb-6") do
            plain "By #{@post.user.name} · #{view_context.time_ago_in_words(@post.created_at)} ago"
          end
          div(class: "prose prose-gray max-w-none") do
            @post.body.split("\n\n").each { |para| p { para } }
          end
        end

        div(class: "flex gap-4 mb-8") do
          a(href: edit_post_path(@post), class: "text-blue-600 hover:underline") { "Edit" }
          a(href: post_path(@post), data: { turbo_method: :delete, turbo_confirm: "Are you sure?" },
            class: "text-red-600 hover:underline") { "Delete" }
        end

        hr(class: "my-8")

        section do
          approved_count = @post.comments.approved.count
          total_count = @post.comments.count
          h2(class: "text-2xl font-bold text-gray-900 mb-6") do
            if view_context.admin?
              "Comments (#{approved_count} approved / #{total_count} total)"
            else
              "Comments (#{approved_count})"
            end
          end
          render CommentForm.new(post: @post, comment: @comment)

          div(class: "mt-8 space-y-6") do
            @comments.each { |comment| render CommentView.new(comment:, post: @post, depth: 0) }
          end
        end
      end
    end
  end

  class CommentForm < Views::Base
    def initialize(post:, comment:, parent_id: nil)
      @post = post
      @comment = comment
      @parent_id = parent_id
    end

    def view_template
      form(action: post_comments_path(@post), method: "post", class: "space-y-4") do
        input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
        input(type: "hidden", name: "comment[parent_id]", value: @parent_id) if @parent_id

        div do
          textarea(name: "comment[body]", placeholder: "Write a comment...", rows: 3,
            class: "w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent")
        end

        div do
          button(type: "submit", class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 cursor-pointer") do
            "Post Comment"
          end
        end
      end
    end
  end

  class CommentView < Views::Base
    def initialize(comment:, post:, depth:)
      @comment = comment
      @post = post
      @depth = depth
    end

    def view_template
      # Skip rendering if comment is not approved and user is not admin
      return unless @comment.status == "approved" || view_context.admin?

      comment_id = "comment-#{@comment.id}"

      div(class: "#{@depth > 0 ? 'ml-8' : ''} border-l-2 border-gray-200 pl-4") do
        div(class: "bg-gray-50 rounded-lg p-4") do
          # Header with user info, status badge, and actions
          div(class: "flex justify-between items-start") do
            div(class: "flex items-center gap-2") do
              div(class: "text-sm text-gray-500") do
                strong { @comment.user.name }
                plain " · #{view_context.time_ago_in_words(@comment.created_at)} ago"
              end

              # Status badge for admins
              if view_context.admin?
                case @comment.status
                when "pending"
                  span(class: "px-2 py-1 text-xs font-semibold text-yellow-800 bg-yellow-100 rounded") { "Pending" }
                when "rejected"
                  span(class: "px-2 py-1 text-xs font-semibold text-red-800 bg-red-100 rounded") { "Rejected" }
                when "approved"
                  span(class: "px-2 py-1 text-xs font-semibold text-green-800 bg-green-100 rounded") { "Approved" }
                end
              end
            end

            # Action buttons
            div(class: "flex gap-3 items-center") do
              # Collapse/expand for threads with replies
              if @comment.replies.any?
                button(
                  class: "text-gray-500 text-sm hover:underline toggle-replies",
                  id: "toggle-btn-#{comment_id}",
                  data: { comment_id: comment_id }
                ) { "Collapse (#{@comment.replies.count})" }
              end

              # Moderation buttons (admin only)
              if view_context.admin?
                if @comment.status == "pending"
                  a(href: approve_post_comment_path(@post, @comment),
                    data: { turbo_method: :patch },
                    class: "text-green-600 text-sm hover:underline") { "Approve" }
                  a(href: reject_post_comment_path(@post, @comment),
                    data: { turbo_method: :patch },
                    class: "text-yellow-600 text-sm hover:underline") { "Reject" }
                end
              end

              # Delete with confirmation
              button(
                class: "text-red-500 text-sm hover:underline delete-comment",
                data: {
                  comment_id: comment_id,
                  comment_excerpt: @comment.excerpt(50)
                }
              ) { "Delete" }
            end
          end

          p(class: "mt-2 text-gray-700") { @comment.body }

          # Reply form (only for approved comments or admins, and if depth < 2)
          if (@comment.status == "approved" || view_context.admin?) && @depth < 2
            details(class: "mt-3") do
              summary(class: "text-blue-600 text-sm cursor-pointer hover:underline") { "Reply" }
              div(class: "mt-2") do
                render CommentForm.new(post: @post, comment: Comment.new, parent_id: @comment.id)
              end
            end
          end
        end

        # Replies section
        if @comment.replies.any?
          visible_replies = view_context.admin? ? @comment.replies : @comment.replies.approved
          div(class: "mt-4 space-y-4", id: "replies-#{comment_id}") do
            visible_replies.each { |reply| render CommentView.new(comment: reply, post: @post, depth: @depth + 1) }
          end
        end
      end
    end
  end

  class NewView < Views::Base
    def initialize(post:)
      @post = post
    end

    def view_template
      div(class: "max-w-4xl mx-auto px-4 py-8") do
        div(class: "mb-6") do
          a(href: posts_path, class: "text-blue-600 hover:underline") { "← Back to posts" }
        end
        h1(class: "text-3xl font-bold text-gray-900 mb-8") { "New Post" }
        render PostForm.new(post: @post)
      end
    end
  end

  class EditView < Views::Base
    def initialize(post:)
      @post = post
    end

    def view_template
      div(class: "max-w-4xl mx-auto px-4 py-8") do
        div(class: "mb-6") do
          a(href: post_path(@post), class: "text-blue-600 hover:underline") { "← Back to post" }
        end
        h1(class: "text-3xl font-bold text-gray-900 mb-8") { "Edit Post" }
        render PostForm.new(post: @post)
      end
    end
  end

  class PostForm < Views::Base
    def initialize(post:)
      @post = post
    end

    def view_template
      url = @post.persisted? ? post_path(@post) : posts_path
      method = @post.persisted? ? "patch" : "post"

      form(action: url, method: "post", class: "space-y-6") do
        input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
        input(type: "hidden", name: "_method", value: method) if @post.persisted?

        if @post.errors.any?
          div(class: "bg-red-50 border border-red-200 rounded-lg p-4") do
            h2(class: "text-red-800 font-semibold") do
              "#{@post.errors.count} error#{'s' if @post.errors.count > 1} prohibited this post from being saved:"
            end
            ul(class: "mt-2 list-disc list-inside text-red-700") do
              @post.errors.full_messages.each { |msg| li { msg } }
            end
          end
        end

        div do
          label(for: "post_title", class: "block text-sm font-medium text-gray-700 mb-1") { "Title" }
          input(type: "text", name: "post[title]", id: "post_title", value: @post.title,
            class: "w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent")
        end

        div do
          label(for: "post_body", class: "block text-sm font-medium text-gray-700 mb-1") { "Body" }
          textarea(name: "post[body]", id: "post_body", rows: 10,
            class: "w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent") do
            @post.body
          end
        end

        div do
          button(type: "submit", class: "bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 cursor-pointer") do
            @post.persisted? ? "Update Post" : "Create Post"
          end
        end
      end
    end
  end

  # ============================================================================
  # CONTROLLER ACTIONS
  # ============================================================================

  def index
    @posts = Post.includes(:user).order(created_at: :desc)
    render IndexView.new(posts: @posts)
  end

  def show
    # Show all root comments for admins, only approved for regular users
    @comments = if admin?
      @post.comments.includes(:user, :replies).root_comments
    else
      @post.comments.includes(:user, :replies).root_comments.approved
    end
    @comment = Comment.new
    render ShowView.new(post: @post, comments: @comments, comment: @comment)
  end

  def new
    @post = Post.new
    render NewView.new(post: @post)
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user

    if @post.save
      redirect_to @post, notice: "Post was successfully created."
    else
      render NewView.new(post: @post), status: :unprocessable_entity
    end
  end

  def edit
    render EditView.new(post: @post)
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was successfully updated."
    else
      render EditView.new(post: @post), status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post was successfully deleted."
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end

  def current_user
    @current_user ||= User.first_or_create!(name: "Demo User", email: "demo@example.com")
  end
  helper_method :current_user

  def admin?
    # Simple admin check - in production, this would check actual user roles
    params[:admin] == "true" || session[:admin] == true
  end
  helper_method :admin?
end
