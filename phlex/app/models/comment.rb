class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy

  validates :body, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }
  validate :maximum_nesting_depth

  scope :approved, -> { where(status: "approved") }
  scope :pending, -> { where(status: "pending") }
  scope :rejected, -> { where(status: "rejected") }
  scope :root_comments, -> { where(parent_id: nil) }

  # Visibility rules:
  # - Approved: visible to everyone
  # - Pending: visible to admins and comment author
  # - Rejected: visible only to admins
  def visible_to?(user, is_admin:)
    return true if is_admin
    return true if status == "approved"
    return true if status == "pending" && user && user.id == user_id
    false
  end

  # Scope to get comments visible to a specific user
  def self.visible_to(user, is_admin:)
    if is_admin
      all
    elsif user
      where("status = ? OR (status = ? AND user_id = ?)", "approved", "pending", user.id)
    else
      approved
    end
  end

  def depth
    parent ? parent.depth + 1 : 0
  end

  def excerpt(length = 50)
    body.truncate(length)
  end

  def editable_by?(user, is_admin:)
    return true if is_admin
    return true if user && user.id == user_id
    false
  end

  private

  def maximum_nesting_depth
    # Max 3 levels means depths 0, 1, 2 are allowed
    # So we check if calculated depth would be >= 3
    return unless parent_id

    calculated_depth = parent ? parent.depth + 1 : 0
    if calculated_depth >= 3
      errors.add(:parent_id, "cannot nest more than 3 levels deep")
    end
  end
end
