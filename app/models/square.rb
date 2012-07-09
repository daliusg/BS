class Square < ActiveRecord::Base
  belongs_to :ship
  belongs_to :game

  attr_accessible :index, :ship_id, :game_id, :hit

end
