class CreateEnemySquares < ActiveRecord::Migration
  def change
    create_table :enemy_squares do |t|
      t.integer :index
      t.integer :ship_id 
      t.integer :game_id
      t.boolean :hit
      
      t.timestamps
    end
  end
end
