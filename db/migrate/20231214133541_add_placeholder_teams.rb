class AddPlaceholderTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :source_game_id, :integer, after: :name
    add_column :teams, :team_type, :integer, default: 0, after: :name, null: false
    add_index :teams, :source_game_id
  end
end
