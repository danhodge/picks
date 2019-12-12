class CreateBowls < ActiveRecord::Migration[5.2]
  def change
    create_table :bowls do |t|
      t.string :name, null: false
      t.string :city, null: false
      t.string :state, null: false

      t.timestamps
    end

    add_index :bowls, :name, unique: true
  end
end
