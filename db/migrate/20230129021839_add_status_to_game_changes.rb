class AddStatusToGameChanges < ActiveRecord::Migration[7.0]
  def change
    add_column :game_changes, :status, :integer, default: 0, after: :previous_home_team_id, null: false
    add_index :game_changes, :status
  end
end
