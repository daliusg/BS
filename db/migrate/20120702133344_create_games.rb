class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.integer :botID
      t.integer :player_id
      t.boolean :my_turn
      t.boolean :started, default: false
      t.boolean :finished, default: false

      t.timestamps
    end
  end
end
