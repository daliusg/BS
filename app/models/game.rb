class Game < ActiveRecord::Base
  belongs_to :player
  has_many :squares

  attr_accessible :botID, :player_id, :my_turn, :started, :finished
  
  # validates :botID, uniqueness: true

  # Create 100 squares and link them to the current game
  def setupSquares
    game_squares = Array.new
    for i in 0..99
      squares.create(index: i, hit: false)
      # Note that ship_id is left at nil (nil = no ship)
    end
  end

  def placeShip (shipID, coords)
    coords.each do |i|
      square = squares.find_by_index(i)
      square.ship = Ship.find(shipID)
      square.save
    end
  end
  
  def toggle_turn
    if my_turn == false
      my_turn = true
    elsif my_turn == true
      my_turn = false
    else  # my_turn not initiated, my_turn == nil, so set to P45's turn
      my_turn = false
    end
  end

end
