class MyShip < ActiveRecord::Base
  belongs_to :game
  belongs_to :ship

  attr_accessible :game_id, :ship_id, :hits, :sunk
end
