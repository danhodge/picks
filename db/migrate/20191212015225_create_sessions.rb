class CreateSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :sessions do |t|
      t.references :user, index: true, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :sessions, :token, unique: true
  end
end
