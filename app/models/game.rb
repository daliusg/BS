class Game < ActiveRecord::Base
  belongs_to :player
  has_many :squares
  has_many :enemy_squares
  has_many :my_ships
  has_many :enemy_ships

  attr_accessible :botID, :player_id, :my_turn, :started, :finished
  attr_accessible :my_hits, :my_misses, :enemy_hits, :enemy_misses

  ############################################################################
  #######################         SETUP        ###############################
  ############################################################################

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

  def placeShip (shipID, coords, who)
    transaction do
      coords.each do |i|
        square = self.send(who).find_by_index(i)
        square.ship_id = shipID
        square.save
      end
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
          placeShip(ship.id, coords, 'enemy_squares')
          placed = true
        else
          direction = rand(4)
          if placementClear(ship.length, direction, coords, "enemy")
            self.placeShip(ship.id, coords, 'enemy_squares')
            placed = true
          end
        end
      end
    end
  end
  
  def placementClear (length, direction, coords, board)
    valid = true
    bowX, bowY = getCoords(coords[0])
    for i in (1...length)
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
        
        if (board == "myBoard")
          if x < 0 || x > 9 || y < 0 || y > 9 || shipPresent(getIndex(x,y), 'squares')
            valid = false
          end
        elsif (board == "enemy")
          if x < 0 || x > 9 || y < 0 || y > 9 || shipPresent(getIndex(x,y), 'enemy_squares')
            valid = false
          end
        end

        if valid
          coords << getIndex(x, y)
        end
      end
    end
    return valid
  end

  def findRandomBow
    valid = false
    while !valid
      x = rand(10)
      y = rand(10)
      index = getIndex(x,y)
      valid = true if !shipPresent(index, 'enemy_squares')
    end
    return x, y  
  end

  ############################################################################
  #####################        GAME LOGIC        #############################
  ############################################################################

  def start
    self.started = true
    self.my_turn = false
    self.save
  end

  def firedUpon (x, y)
    index = getIndex(x,y)
    target = self.squares.find_by_index(index)
    hit = target.checkHit

    if hit == 'hit'
      self.my_hits += 1
      ship = target.ship # Get ship for return
      if processHit(index, ship, 'my_ships') #processHit returns T/F for sunk
        sunk = ship.name
      end
      if checkForLoss('my_ships')
        game_status = 'lost' 
        self.finished = true
      else 
        toggle_turn
      end

    elsif hit == 'already_hit'
      ship = target.ship
      toggle_turn

    else # 'miss'
      ship = nil
      self.my_misses += 1
      toggle_turn
    end

    self.save 
    returnHash = {status: hit}
    if !sunk.nil? then returnHash.merge!({sunk: sunk}) end
    if !game_status.nil? then returnHash.merge!({game_status: game_status})  end

    retJson = returnHash.to_json
    return retJson
  end

  # Logic to fire on self-created enemy when P45 server not working
  # status = hit or miss (or 'already_hit')
  # ship - ship (object) that was hit
  # sunk = if hit, T/F (supposed to be name of ship sunk)
  # game_status = 'lost' when game is lost
  # error = Error message if something went wrong (P45 only)
  # prize = Will contain prize when sunk all enemy ships (P45 only)
  def fireOnEnemy (x, y)
    index = getIndex(x,y)
    target = self.enemy_squares.find_by_index(index)
    hit = target.checkHit

    if hit == 'hit'
      self.enemy_hits += 1
      ship = target.ship # Get ship for return
      if processHit(index, ship, 'enemy_ships') 
        sunk = ship.name
      end
      if checkForLoss('enemy_ships')
        game_status = 'lost' 
        self.finished = true
      else 
        toggle_turn
      end

    elsif hit == 'already_hit'
      ship = target.ship
      toggle_turn

    else # 'miss'
      ship = nil
      self.enemy_misses += 1
      toggle_turn
    end

    self.save 
    returnHash = {status: hit}
    if !sunk.nil? then returnHash.merge!({sunk: sunk}) end
    if !game_status.nil? then returnHash.merge!({game_status: game_status})  end

    retJson = returnHash.to_json
    return retJson
  end

  # returns sunk (T/F)
  def processHit (index, ship, who)
    ship = self.send(who).find_by_ship_id(ship) 
    ship.hits += 1
    logger.debug("ship.hits: #{ship.attributes.inspect}")
    logger.debug("ship.ship.length: #{ship.ship.attributes.inspect}")
    logger.debug("ship.sunk: #{ship.sunk}")
    if (ship.ship.length == ship.hits)
      ship.sunk = true
      ship.save
      logger.debug("ship.sunk, after being set/not set: #{ship.attributes.inspect}")
      return true
    else
      ship.save
      return false
    end
  end

  # Checks to see if all ships are sunk
  # 'who' - either 'my_ships' or 'enemy_ships', depending on who's being checked
  def checkForLoss (who)
    loss = false
    num_sunk = 0
    fleet = self.send(who).find(:all)
    fleet.each do |ship|
      if ship.sunk
        num_sunk += 1 
      end
    end
    if num_sunk == 7
      loss = true
      self.finished = true
    end
    return loss
  end
  ############################################################################
  ####################     ACCESSORIES / HELPERS      ########################
  ############################################################################

  def sunkShips (who)
    ships = self.send(who).find_all_by_sunk(true)  #This only returns one value!
    logger.debug("ships after first search.... #{ships.inspect}")
    if !ships.nil?
      ships = ships.map { |ship| ship.ship.name }# { |ship| ship.ship.name }
      logger.debug("shipArr.... #{ships.inspect}")
    end
    return ships
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
    return y*10 + x
  end

  def getCoords (index)
    return  index%10, index/10
  end

   # T if ship present, F otherwise
  def shipPresent (index, who_squares)
    !self.send(who_squares).find_by_index(index).ship_id.blank?
  end

  def getStats (player)
    if player == "me"
      my_hits = self.my_hits
      my_misses = self.my_misses
      my_sunk_ships = sunkShips('my_ships')
      finished = self.finished
      stats =  {my_hits: my_hits,
              my_misses: my_misses,
              my_sunk_ships: my_sunk_ships,
              finished: finished}
    else # player == "enemy"
      enemy_hits = self.enemy_hits
      enemy_misses = self.enemy_misses
      enemy_sunk_ships = sunkShips('enemy_ships')
      finished = self.finished
      stats =  {enemy_hits: enemy_hits,
              enemy_misses: enemy_misses,
              enemy_sunk_ships: enemy_sunk_ships,
              finished: finished}
    end
  end

end