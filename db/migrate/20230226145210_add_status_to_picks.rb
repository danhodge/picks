class AddStatusToPicks < ActiveRecord::Migration[7.0]
  def change
    add_column :picks, :status, :integer, default: 0, after: :points, null: false
    add_index :picks, :status
  end
end
