class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy

  validates :body, presence: true
  validates :moderation_status, inclusion: { in: %w[pending approved rejected] }
  validate :maximum_nesting_depth

  scope :approved, -> { where(moderation_status: "approved") }
  scope :pending, -> { where(moderation_status: "pending") }
  scope :rejected, -> { where(moderation_status: "rejected") }
  scope :root_comments, -> { where(parent_id: nil) }

  def depth
    parent ? parent.depth + 1 : 0
  end

  def excerpt(length = 50)
    body.truncate(length)
  end

  def approve!
    update!(moderation_status: "approved")
  end

  def reject!
    update!(moderation_status: "rejected")
  end

  def pending?
    moderation_status == "pending"
  end

  def approved?
    moderation_status == "approved"
  end

  def rejected?
    moderation_status == "rejected"
  end

  def edited?
    edited_at.present?
  end

  def editable_by?(user)
    return false unless user
    user.admin? || user == self.user
  end

  def visible_to?(user)
    return true if approved?
    return true if user&.admin?
    return true if pending? && user == self.user
    false
  end

  def self.visible_to(user)
    if user&.admin?
      all
    else
      where(moderation_status: "approved")
        .or(where(moderation_status: "pending", user_id: user&.id))
    end
  end

  private

  def maximum_nesting_depth
    if depth >= 3
      errors.add(:parent_id, "comments can only be nested 3 levels deep")
    end
  end
end
