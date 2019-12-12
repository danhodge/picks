class CreateGames < ActiveRecord::Migration[5.2]
  def change
    create_table :games do |t|
      t.references :season
      t.references :bowl, index: true
      t.integer :visiting_team_id, null: false
      t.integer :home_team_id, null: false
      t.float :point_spread, null: false
      t.datetime :game_time, null: false

      t.timestamps
    end

    add_index :games, [:season_id, :bowl_id], unique: true
    add_index :games, :visiting_team_id
    add_index :games, :home_team_id
  end
end
