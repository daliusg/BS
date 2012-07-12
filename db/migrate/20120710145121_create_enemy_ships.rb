class CreateEnemyShips < ActiveRecord::Migration
  def change
    create_table :enemy_ships do |t|
      t.integer :game_id 
      t.integer :ship_id 
      t.integer :hits, default: 0
      t.boolean :sunk, default: false 
      
      t.timestamps
    end
  end
end
