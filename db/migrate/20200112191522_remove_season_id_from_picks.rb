class RemoveSeasonIdFromPicks < ActiveRecord::Migration[5.2]
  def change
    remove_index :picks, name: :index_picks_on_season_id_and_participant_id_and_game_id
    remove_column :picks, :season_id

    add_index :picks, [:participant_id, :game_id], unique: true
  end
end
