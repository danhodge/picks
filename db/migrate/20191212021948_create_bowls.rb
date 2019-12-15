class CreateBowls < ActiveRecord::Migration[5.2]
  def change
    create_table :bowls do |t|
      t.string :name, null: false
      t.string :city
      t.string :state

      t.timestamps
    end

    add_index :bowls, :name, unique: true
  end
end
