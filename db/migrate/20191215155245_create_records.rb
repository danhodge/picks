class CreateRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :records do |t|
      t.references :season, null: false
      t.references :team, index: true, null: false
      t.integer :wins, null: false
      t.integer :losses, null: false
      t.integer :ranking

      t.timestamps
    end

    add_index :records, [:season_id, :team_id], unique: true
  end
end
