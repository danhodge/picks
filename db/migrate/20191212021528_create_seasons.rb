class CreateSeasons < ActiveRecord::Migration[5.2]
  def change
    create_table :seasons do |t|
      t.integer :year, null: false

      t.timestamps
    end

    add_index :seasons, :year, unique: true
  end
end
