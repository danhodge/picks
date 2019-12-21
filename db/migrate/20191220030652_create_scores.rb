class CreateScores < ActiveRecord::Migration[5.2]
  def change
    create_table :scores do |t|
      t.references :game, index: true, null: false
      t.references :team, index: true, null: false
      t.integer :points, null: false
      t.integer :quarter, null: false
      t.integer :time_remaining_seconds, null: false

      t.timestamps
    end
  end
end
