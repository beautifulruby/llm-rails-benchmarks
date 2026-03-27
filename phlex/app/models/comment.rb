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

  def depth
    parent ? parent.depth + 1 : 0
  end

  def excerpt(length = 50)
    body.truncate(length)
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
