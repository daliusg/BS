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

  # Create 100 squares for each player and link them to the current game
  def setupSquares
    for i in 0..99
      self.squares.build(index: i)
      self.enemy_squares.build(index: i)
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
          placeShip(ship.id, coords, "enemy")
          placed = true
        else
          direction = rand(4)
          if placementClear(ship.length, direction, coords, "enemy")
            self.placeShip(ship.id, coords, "enemy")
            placed = true
          end
        end
      end
    end
  end
  
  # Randomly find an open spot to place the bow of the ship  
  def findRandomBow
    valid = false
    while !valid
      x = rand(10)
      y = rand(10)
      index = getIndex(x,y)
      valid = true if !shipPresent(index, "enemy")
    end
    return x, y  
  end

  # Checks if a location is clear for ship placement - includes checking
  # if another ship is already there or if the ship would be out of bounds
  # 'coords' are the bow's coordinates, 'direction' b/w 0-3 for cardinal dirs
  # This method is used for placing both my ships and enemy ships, so 'who' -
  # either "me" or "enemy" indicates which
  def placementClear (length, direction, coords, who)
    valid = true
    bowX, bowY = getCoords(coords[0])
    for i in (1...length)
      if valid == true  
        if direction == 0   #North
          x = bowX
          y = bowY - i
        elsif direction == 1 #South
          x = bowX
          y = bowY + i
        elsif direction == 2 #East
          x = bowX + i
          y = bowY
        else                #West
          x = bowX - i
          y = bowY
        end
        if x < 0 || x > 9 || y < 0 || y > 9 || 
                                        shipPresent(getIndex(x,y), who)
          valid = false
        end
        if valid
          coords << getIndex(x, y)
        end
      end
    end
    return valid
  end
  
  # This where a ship actually gets 'placed' on a square, via setting ship_id
  # 'who' is either 'me' or 'enemy', based on who is being placed
  # 'coords' is an array of indexes where ship is to be placed
  def placeShip (shipID, coords, who)
    which_squares = (who == "me") ? "squares" : "enemy_squares"
    transaction do
      coords.each do |i|
        square = self.send(which_squares).find_by_index(i)
        square.ship_id = shipID
        square.save
      end
    end
  end
  ############################################################################
  #####################        GAME LOGIC        #############################
  ############################################################################

  # sets game attributes to appropriate starting values
  def start
    self.started = true
    self.my_turn = true
    self.save
  end

  # Note - this is not used to fire on P45, just my own internal enemy
  # Logic to fire on both me and enemy, arg 'who' determines who
  # status = hit or miss (or 'already_hit')
  # ship - ship (object) that was hit
  # sunk = name of sunk ship
  # game_status = 'lost' when game is lost
  def fire (x, y, who)  
    index = getIndex(x,y)
    board = (who == "me") ? 'squares' : 'enemy_squares'
    target = self.send(board).find_by_index(index)
    hit = target.checkHit

    if hit == 'hit'
      (who=="me") ? self.my_hits+=1 : self.enemy_hits+=1
      ship = target.ship 
      ships = (who == "me") ? 'my_ships' : 'enemy_ships'
      if processHit(ship, who) #processHit returns T/F for sunk
        sunk = ship.name
      end
      # Check either my_ships or enemy_ships board for total destruction
      if checkForLoss(who)
        game_status = 'lost' 
        self.finished = true
      else 
        toggle_turn
      end

    elsif hit == 'already_hit'
      toggle_turn

    else # 'miss'
      (who=="me") ? self.my_misses+=1 : self.enemy_misses+=1
      toggle_turn
    end

    self.save 
    returnHash = {status: hit}
    if !sunk.nil? then returnHash.merge!({sunk: sunk}) end
    if !game_status.nil? then returnHash.merge!({game_status: game_status}) end

    retJson = returnHash.to_json
    return retJson
  end

  # updates database appropriately for a hit, returns if ship is sunk (T/F)
  def processHit (ship, who)
    which_ships = (who == "me") ? "my_ships" : "enemy_ships"
    my_ship = self.send(which_ships).find_by_ship_id(ship) 
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

  # Checks to see if all ships are sunk
  # 'who' - either 'me' or 'enemy', depending on who's being checked
  def checkForLoss (who)
    which_ships = (who == "me") ? "my_ships" : "enemy_ships"
    loss = false
    num_sunk = 0
    fleet = self.send(which_ships).find(:all)
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

  # When playing against P45, I don't have to figure out results of firing,
  # they return that data (hit/miss/sunk/game_status) for me.  I still have 
  # to update the model with this info though so things like stats stay correct
  def processP45response(json_result)
    result = JSON.parse(json_result.body)
    status = result["status"] 
    sunk = result["sunk"]
    game_status = result["game_status"]

    if status == 'hit'
      self.enemy_hits += 1
    elsif status == 'miss'
      self.enemy_misses += 1
    end

    if !sunk.nil?
      # P45's naming convention is a bit diffenent, so this is necessary...
      if sunk == "Patrol Boat"
        p1 = Ship.find_by_name("Patrol 1")
        if self.my_ships.find_by_ship_id(p1).sunk
          sunk = "Patrol 2"
        else
          sunk = "Patrol 1"
        end
      end
      if sunk == "Submarine"
        s1 = Ship.find_by_name("Submarine 1")
        if self.my_ships.find_by_ship_id(s1).sunk
          sunk = "Submarine 2"
        else
          sunk = "Submarine 1"
        end
      end
      
      ship = Ship.find_by_name(sunk)
      eShip = self.enemy_ships.find_by_ship_id(ship)
      eShip.sunk = true
      eShip.save
    end

    if game_status == "lost"
      self.finished = true
    else 
      toggle_turn
    end
    self.save
  end
  ############################################################################
  ####################     ACCESSORIES / HELPERS      ########################
  ############################################################################

  # Returns an array of all sunk ships (for 'who')
  def sunkShips (who)
    which_ships = (who == "me") ? "my_ships" : "enemy_ships"
    ships = self.send(which_ships).find_all_by_sunk(true)
    if !ships.nil?
      ships = ships.map { |ship| ship.ship.name }
    end
    return ships
  end

  # Self-explanatory
  def toggle_turn
    if self.my_turn == false
      self.my_turn = true
    else ## my_turn == true
      self.my_turn = false
    end
    self.save
  end
    
  # Converts x, y coordinates into a single index value (0-99)
  def getIndex (x,y)
    return y*10 + x
  end

  # Opposite of getIndex, converts index into x,y coordinates
  def getCoords (index)
    return  index%10, index/10
  end

   # Simple test for ship presence - T/F
  def shipPresent (index, who)
    who_squares = (who == "me") ? "squares" : "enemy_squares"
    !self.send(who_squares).find_by_index(index).ship_id.blank?
  end

  # Return stats for a given player, hash converted to json string
  def getStats (player)
    if player == "me"
      my_hits = self.my_hits
      my_misses = self.my_misses
      my_sunk_ships = sunkShips("me")
      finished = self.finished
      stats =  {my_hits: my_hits,
              my_misses: my_misses,
              my_sunk_ships: my_sunk_ships,
              finished: finished}
      statsRet = stats.to_json
      return statsRet

    else # player == "enemy"
      enemy_hits = self.enemy_hits
      enemy_misses = self.enemy_misses
      enemy_sunk_ships = sunkShips("enemy")
      finished = self.finished
      stats =  {enemy_hits: enemy_hits,
              enemy_misses: enemy_misses,
              enemy_sunk_ships: enemy_sunk_ships,
              finished: finished}
      statsRet = stats.to_json
      return statsRet
    end
  end

end