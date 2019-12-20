class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :uuid, null: false
      t.integer :user_type, null: false, default: 1
      t.string :password
      t.string :token

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :uuid, unique: true
    add_index :users, :token, unique: true
  end
end
