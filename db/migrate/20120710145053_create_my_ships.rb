class CreateMyShips < ActiveRecord::Migration
  def change
    create_table :my_ships do |t|
      t.integer :game_id 
      t.integer :ship_id 
      t.integer :hits, default: 0
      t.integer :sunk, default: false 

      t.timestamps
    end
  end
end
