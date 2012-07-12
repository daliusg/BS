class Game < ActiveRecord::Base
  belongs_to :player
  has_many :squares
  has_many :enemy_squares
  has_many :my_ships
  has_many :enemy_ships

  attr_accessible :botID, :player_id, :my_turn, :started, :finished
  attr_accessible :my_hits, :my_misses, :enemy_hits, :enemy_misses
  
  # Create 100 squares and link them to the current game
  def setupSquares
    game_squares = Array.new
    for i in 0..99
      self.squares.build(index: i, hit: false)
      self.enemy_squares.build(index: i, hit: false)
      # Note that ship_id is left at default of nil (nil = no ship)
    end
    self.save
  end
  
  # Create the ships in my_ships & enemy_ships tables
  # These tables are used to track hits on individual ships
  def createShips
    for ship in Ship.find(:all, :order => "id")
      self.my_ships.build(ship_id: ship.id)
      self.enemy_ships.build(ship_id: ship.id)
    end
    self.save
  end

  def placeShip (shipID, coords)
    coords.each do |i|
      square = squares.find_by_index(i)
      square.ship = Ship.find(shipID)
      square.save
    end
  end

  #randomly setup enemy board
  def setupEnemyBoard
    ships = Ship.find(:all, :order => "id")
    ships.each do |ship|
      placed = false
      while !placed
        coords = []
        bow = findRandomBow
        coords << getIndex(bow[0], bow[1])
        if ship.length == 1
          placeEnemyShip(ship, coords)
          placed = true
        else
          direction = rand(4)
          if placementClear(ship.length, direction, coords, "enemy")
            self.placeEnemyShip(ship, coords)
            placed = true
          end
        end
      end
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
      self.my_hits += 1
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
    fleet = self.my_ships.find(:all)
    fleet.each do |ship|
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

  def enemySunkShips
    ships = enemy_ships.find_by_sunk(true)
  end

  def toggle_turn
    if self.my_turn == false
      self.my_turn = true
    else ## my_turn == true
      self.my_turn = false
    end
    self.save
  end
    
  def getIndex (x,y)
    return y*10 +x
  end

  def getCoords (index)
    return  index%10, index/10
  end

  def findRandomBow
    valid = false
    while !valid
      x = rand(10)
      y = rand(10)
      index = getIndex(x,y)
      valid = true if !enemyShipPresent(index)
    end
    return x, y  
  end

  def placementClear (length, direction, coords, board)
    valid = true
    bowX, bowY = getCoords(coords[0])
    logger.debug("bowX, bowY:  #{bowX}, #{bowY}")
    for i in (1...length)
      logger.debug("i: #{i}")
      logger.debug("valid: #{valid}")
      logger.debug("direction: #{direction}")
      if valid == true  
        if direction == 0 #North
          x = bowX
          y = bowY - i
        elsif direction == 1 #South
          x = bowX
          y = bowY + i
        elsif direction == 2 #East
          x = bowX + i
          y = bowY
        else  #West
          x = bowX - i
          y = bowY
        end
        
        logger.debug("board: #{board}")
        if (board == "myBoard")
          logger.debug("valid b/f shipPresent: #{valid}")      
          if x < 0 || x > 9 || y < 0 || y > 9 || shipPresent(getIndex(x,y))
            valid = false
          end
          logger.debug("valid after shipPresent: #{valid}")
        elsif (board == "enemy")
          if x < 0 || x > 9 || y < 0 || y > 9 || enemyShipPresent(getIndex(x,y))
            valid = false
          end
        end

        logger.debug("valid: #{valid}")
        if valid
          coords << getIndex(x, y)
        end
      end
    end
    logger.debug("valid: #{valid}")
    return valid
  end

   # T if ship present, F otherwise
  def shipPresent (index)
    shipID = self.squares.find_by_index(index).ship_id
    logger.debug("shipID:  #{shipID}")
    if shipID 
      return true
    else 
      return false
    end
  end

  # T if ship present, F otherwise
  def enemyShipPresent (index)
    !self.enemy_squares.find_by_index(index).ship_id.blank?
  end

  def placeEnemyShip (ship, coords)
    coords.each do |i|
      enemy_square = enemy_squares.find_by_index(i)
      enemy_square.ship_id = ship
      enemy_square.save
    end
  end

end