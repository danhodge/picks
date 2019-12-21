class CreatePicks < ActiveRecord::Migration[5.2]
  def change
    create_table :picks do |t|
      t.references :season, null: false
      t.references :participant, index: true, null: false
      t.references :game, index: true, null: false
      t.references :team, index: true, null: false
      t.integer :points, null: false

      t.timestamps
    end

    add_index :picks, [:season_id, :participant_id, :game_id], unique: true
  end
end
