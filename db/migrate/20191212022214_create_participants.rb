class CreateParticipants < ActiveRecord::Migration[5.2]
  def change
    create_table :participants do |t|
      t.references :season, index: true, null: false
      t.references :user, index: true
      t.string :nickname, null: false
      t.integer :tiebreaker, null: false

      t.timestamps
    end

    add_index :participants, [:nickname, :season_id], unique: true
  end
end
