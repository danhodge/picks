class ChangeDefaultGameStatus < ActiveRecord::Migration[7.0]
  def change
    change_column_default :games, :game_status, from: 1, to: 0
    change_column_null :games, :game_status, false
  end
end
