class AddGameStatus < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :game_status, :integer, default: 1, after: :game_type
  end
end
