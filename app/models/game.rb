class Game < ActiveRecord::Base
  belongs_to :player
  has_many :squares
  has_many :my_ships
  has_many :enemy_ships

  attr_accessible :botID, :player_id, :my_turn, :started, :finished
  attr_accessible :my_hits, :my_misses, :enemy_hits, :enemy_misses
  
  # Create 100 squares and link them to the current game
  def setupSquares
    game_squares = Array.new
    for i in 0..99
      squares.create(index: i, hit: false)
      # Note that ship_id is left at nil (nil = no ship)
    end
  end

  # Create the ships in my_ships & enemy_ships tables
  # These tables are used to track hits on individual ships
  def createShips
    for ship in Ship.find(:all, :order => "id")
      my_ships.create(ship_id: ship)
      enemy_ships.create(ship_id: ship)
    end
  end

  def placeShip (shipID, coords)
    coords.each do |i|
      square = squares.find_by_index(i)
      square.ship = Ship.find(shipID)
      square.save
    end
  end
  
  def start
    self.started = true
    self.my_turn = false
    self.save
  end

  # processes P45 firing --- Returns hit, ship
  def firedUpon (index)
    square = squares.find_by_index(index)
    hit = square.checkHit
    if hit == 'hit'
      ship = square.ship # Get ship for return
      sunk = processHit(index, ship)
      if checkForLoss
        self.finished = true
      end

    elsif hit == 'already_hit'
      ship = square.ship

    else # 'miss'
      ship = nil
      self.my_misses += 1
    end

    self.save 
    return hit, ship
  end
  
  # returns sunk (T/F)
  def processHit (index, ship)
    self.my_hits += 1
    my_ship = my_ships.find_by_ship_id(ship) 
    my_ship.hits += 1
    if (my_ship.ship.length == my_ship.hits)
      my_ship.sunk = true
      my_ship.save
      return true
    else
      my_ship.save
      return false
    end
  end

  def checkForLoss
    loss = false
    num_sunk = 0
    fleet = my_ships.find(:all)
    for ship in fleet
      if ship.sunk
        num_sunk += 1 
      end
    end
    if num_sunk == 7
      loss = true
    end
    return loss
  end
  
  def mySunkShips
    ships = my_ships.find_by_sunk(true)
  end

  def toggle_turn
    if self.my_turn == false
      self.my_turn = true
    else ## my_turn == true
      self.my_turn = false
    end
    self.save
  end

end