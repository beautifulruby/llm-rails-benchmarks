class AddModerationStatusToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :moderation_status, :string, default: "pending", null: false
    add_index :comments, :moderation_status
  end
end
