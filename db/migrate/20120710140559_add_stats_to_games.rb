class AddStatsToGames < ActiveRecord::Migration
  def change
    add_column :games, :my_hits, :integer, default: 0
    add_column :games, :my_misses, :integer, default: 0
    add_column :games, :enemy_hits, :integer, default: 0
    add_column :games, :enemy_misses, :integer, default: 0
  end
end
