class CreateFinalScores < ActiveRecord::Migration[5.2]
  def change
    create_table :final_scores do |t|
      t.references :game, null: false
      t.references :team, index: true, null: false
      t.integer :points, null: false

      t.timestamps
    end

    add_index :final_scores, [:game_id, :team_id], unique: true
  end
end
