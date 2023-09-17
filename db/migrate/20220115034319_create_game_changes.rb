class CreateGameChanges < ActiveRecord::Migration[5.2]
  def change
    create_table :game_changes do |t|
      t.references :game, index: true, null: false
      t.references :new_team, index: true, null: false
      t.integer :previous_visiting_team_id
      t.integer :previous_home_team_id

      t.timestamps
    end

    add_index :game_changes, :previous_visiting_team_id
    add_index :game_changes, :previous_home_team_id
  end
end
