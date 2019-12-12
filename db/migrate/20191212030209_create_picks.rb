class CreatePicks < ActiveRecord::Migration[5.2]
  def change
    create_table :picks do |t|
      t.references :season
      t.references :participant, index: true
      t.references :game, index: true
      t.references :team, index: true
      t.integer :points, null: false

      t.timestamps
    end

    add_index :picks, [:season_id, :participant_id, :game_id], unique: true
  end
end
