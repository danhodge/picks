class CreateGames < ActiveRecord::Migration[5.2]
  def change
    create_table :games do |t|
      t.references :season, null: false
      t.references :bowl, index: true, null: false
      t.datetime :game_time, null: false
      t.integer :visiting_team_id, null: false
      t.integer :home_team_id, null: false
      t.float :point_spread
      t.integer :game_type, null: false, default: 1

      t.timestamps
    end

    add_index :games, [:season_id, :bowl_id], unique: true
    add_index :games, :visiting_team_id
    add_index :games, :home_team_id
  end
end
