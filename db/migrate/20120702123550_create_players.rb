class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name
      t.string :email
      t.integer :wins, default: 0
      t.integer :losses, default: 0
      t.decimal :average

      t.timestamps
    end
  end
end
