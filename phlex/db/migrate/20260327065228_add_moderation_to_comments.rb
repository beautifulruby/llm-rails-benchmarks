class AddModerationToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :status, :string, default: "pending", null: false
    add_index :comments, :status
  end
end
