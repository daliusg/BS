require 'test_helper'

class GameTest < ActiveSupport::TestCase
  
  test "setupSquares creates 100 unique squares for each player" do
    game = Game.create
    game.setupSquares
    assert_equal 100, game.squares.find(:all).count
    assert_equal 100, game.enemy_squares.find(:all).count

    arr = (0..99).to_a
    game.squares.each do |square|
      arr.delete(square.index)
    end
    assert_equal [], arr

    arr = (0..99).to_a
    game.enemy_squares.each do |square|
      arr.delete(square.index)
    end
    assert_equal [], arr
  end

  test "setupShips creates one record for each \
        ship in my_ship and enemy_ship tables" do
    game = Game.create
    game.createShips
    assert_equal 7, game.my_ships.find(:all).count
    assert_equal 7, game.enemy_ships.find(:all).count

    ships = []
    Ship.find(:all).each do |ship|
      ships << ship.name
    end
    game.my_ships.each do |my_ship|
      ships.delete(my_ship.ship.name)
    end
    assert_equal [], ships

    ships = []
    Ship.find(:all).each do |ship|
      ships << ship.name
    end
    game.enemy_ships.each do |enemy_ship|
      ships.delete(enemy_ship.ship.name)
    end
    assert_equal [], ships
  end

  

  test "setupEnemyBoard places one of each ship on enemy board" do
    game = Game.create
    game.setupSquares
    game.setupEnemyBoard

    ships = Ship.find(:all)
    # For each ship, make sure number of squares matches ship length
    ships.each do |ship|
      count = game.enemy_squares.find_all_by_ship_id(ship).count
      assert_equal ship.length, count
    end

    # Make sure locations are OK...
    # For each ship, make sure squares are next to each other (not scattered)
    ships.each do |ship|
      squares = game.enemy_squares.find_all_by_ship_id(ship.id, order: "'index'")
      size = squares.size
      if size > 1
        diffPossible = [1,10]
        # get first difference
        diff = squares[1].index - squares[0].index
        assert diffPossible.include?(diff), "index difference must be 1 or 10"
        # check to make sure index differentials same between each square
        if size > 2
          for i in (1...size-1)
            ## loop through squares, through index-1, making sure diff stays the same
            next_diff = squares[i+1].index - squares[i].index
            assert_equal diff, next_diff, "indexes must have same differential" 
          end 
        end
      end
    end
  end  

  test "findRandomBow returns coordinates of an empty square" do
    game = games(:one)
    game.setupSquares
    ship1 = ships(:one)
    coords1 = [0,1,2,3,4]
    ship2 = ships(:two)
    coords2 = [80, 70, 60, 50]
    ship3 = ships(:three)
    coords3 = [66, 67, 68]
    # place 3 ships
    game.placeShip(ship1.id, coords1, "enemy" )
    game.placeShip(ship2.id, coords2, "enemy" )
    game.placeShip(ship3.id, coords3, "enemy" )

    # run findRandomBow 100 times and check to make sure none of results
    # are one of the occupied squares
    hasShip = coords1+coords2+coords3
    results = []
    100.times do
      x, y = game.findRandomBow
      results << game.getIndex(x,y)
    end
    alwaysEmptySquare = true
    results.each do |result|
      if alwaysEmptySquare
        alwaysEmptySquare = !hasShip.include?(result)
      end
    end
    assert_equal true, alwaysEmptySquare, "Non-empty square was selected"
  end

  # placementClear should return false if placement is not valid
  test "placementClear does not allow placing ship \
        on top of another or out of bounds" do
    # directions indicate which way stern lies=>0-north 1-south 2-east 3-west
    # length, direction, coords, board
    # enemy, myBoard
    game = games(:one)
    ship1 = ships(:one)
    coords1 = [0, 1, 2, 3, 4]
    game.setupSquares
    game.placeShip(ship1.id, coords1, "me" )
    
    #Try placing ship2 so that stern rests on top of ship1
    ship2 = ships(:two)
    bow2 = [30]
    assert !game.placementClear(ship2.length, 0, bow2, "me")

    #Try placing ship3 so that it lies off the grid
    ship3 = ships(:three)
    bow3 = [9]
    assert !game.placementClear(ship3.length, 2, bow3, "me")    
  end

  test "placeSh1p places correct ship in correct location" do
    game = games(:one)
    ship = ships(:one)
    game.setupSquares
    coords = [10, 11, 12, 13, 14]

    #place on my board
    game.placeShip(ship.id, coords, "me")
    #place on enemy's board
    game.placeShip(ship.id, coords, "enemy")

    # for every square in length of ship, check that id matches correct ship
    #for my board...
    for i in (0...ship.length)
      ship_id = game.squares.find_by_index(coords[i]).ship_id
      assert_equal ship.id, ship_id
    end

    #for enemy's board...
    for i in (0...ship.length)
      ship_id = game.enemy_squares.find_by_index(coords[i]).ship_id
      assert_equal ship.id, ship_id
    end
  end
  
  test "start sets attributes correctly" do
    game = games(:one)
    game.start
    assert_equal true, game.started
    assert_equal true, game.my_turn
  end

  test "fire returns correct responses" do
    # setup a game and place a carrier at squares 10-14
    game = games(:one)
    game.setupSquares
    game.createShips
    ship1 = ships(:one)
    coords1 = [10,11,12,13,14]
    game.placeShip(ship1.id, coords1, "me")
    #mark square 10 as hit
    square10 = game.squares.find_by_index(10)
    square10.ship_id = ship1.id
    square10.hit = true
    square10.save
    game.processHit(ship1, "me")

    #fire on previously un-hit spot on carrier - index 11(1,1)
    retval = game.fire(1,1,"me")
    result = JSON.parse(retval)
    assert_equal "hit", result["status"]

    #fire on previously hit spot on carrier - index 10(0,1)
    retval = game.fire(0,1,"me")
    result = JSON.parse(retval)
    assert_equal "already_hit", result["status"]

    # fire on empty square - index 0(0,0)
    retval = game.fire(0,0,"me")
    result = JSON.parse(retval)
    assert_equal "miss", result["status"]

    # make sure "sunk" and "game_status" are returned nil
    assert_equal nil, result["sunk"]
    assert_equal nil, result["game_status"]

    #sink the ship, make sure sunk is returned
    #spots 10 & 11 already hit, mark 12, 13 as hit
    square12 = game.squares.find_by_index(12)
    square12.ship_id = ship1.id
    square12.hit = true
    square12.save
    game.processHit(ship1, "me")
    square13 = game.squares.find_by_index(13)
    square13.ship_id = ship1.id    
    square13.hit = true
    square13.save
    game.processHit(ship1, "me")
    #fire on 14 to sink it
    retval = game.fire(4,1, "me")
    result = JSON.parse(retval)
    assert_equal "Carrier", result["sunk"]

    #Place and sink the rest of the fleet to test for correct "lost" response
    #First, place the fleet
    ship2 = ships(:two)
    coords2 = [20,21,22,23]
    game.placeShip(ship2.id, coords2, "me")
    ship3 = ships(:three)
    coords3 = [30,31,32]
    game.placeShip(ship3.id, coords3, "me")
    ship4 = ships(:four)
    coords4 = [40,41]
    game.placeShip(ship4.id, coords4, "me")
    ship5 = ships(:five)
    coords5 = [50,51]
    game.placeShip(ship5.id, coords5, "me")
    ship6 = ships(:six)
    coords6 = [60]
    game.placeShip(ship6.id, coords6, "me")
    ship7 = ships(:seven)
    coords7 = [70]
    game.placeShip(ship7.id, coords7, "me")

    #sink all but last ship
    coords = coords2+coords3+coords4+coords5+coords6
    coords.each do |index|
      x, y = game.getCoords(index)
      game.fire(x, y, "me")
    end
    #now fire on last ship and check for "lost" response
    x, y = game.getCoords(coords7[0])
    retval = game.fire(x, y, "me")
    result = JSON.parse(retval)
    assert_equal "lost", result["game_status"]
  end

  test "processHit updates number of hits and returns T/F for sunk" do
    game = games(:one)
    game.createShips
    ship = ships(:one)

    #assert hits goes up by one when ship is hit
    assert_difference('game.my_ships.find_by_ship_id(ship).hits') do
      sunk = game.processHit(ship, "me")
    end
    Rails::logger.debug("############  assert_difference DONE ###########")

    # sink ship7 (length of 1) and make sure that hitting it sinks it
    # and process hit returns correct value
    ship7 = ships(:seven)
    my_ship = game.my_ships.find_by_ship_id(ship7)
    assert_equal false, my_ship.sunk
    sunk = game.processHit(ship7, "me")
    assert_equal true, sunk

  end

  test "test checkForLoss correctly returns if all ships are sunk" do
    game = games(:one)
    game.createShips
    fleet = game.my_ships.find(:all)
    #sink all the ships
    fleet.each do |ship|
      ship.sunk = true
      ship.save
    end
    assert_equal true, game.checkForLoss("me")
  end

  test "sunkShips returns correct list of sunk ships" do
    game = games(:one)
    game.createShips
    ship1 = ships(:one)
    ship2 = ships(:two)
    # "sink" 2 of ships
    ship1 = game.my_ships.find_by_ship_id(ship1)
    ship1.sunk = true
    ship1.save
    ship2 = game.my_ships.find_by_ship_id(ship2)
    ship2.sunk = true
    ship2.save

    assert_equal  [ship1.ship.name, ship2.ship.name].sort!, game.sunkShips("me")
  end

  test "toggle_turn toggles game.my_turn" do
    game = games(:one)
    game.my_turn = false
    game.save
    game.toggle_turn
    assert_equal true, game.my_turn
    game.toggle_turn
    assert_equal false, game.my_turn
  end

  test "getIndex returns correct index" do
    game = games(:one)
    x, y = 0, 0
    assert_equal 0, game.getIndex(x,y)
    x, y = 9, 9
    assert_equal 99, game.getIndex(x,y)
    x, y = 9, 0
    assert_equal 9, game.getIndex(x,y)
    x, y = 0, 9
    assert_equal 90, game.getIndex(x,y)
  end

  test "getCoords returns correct coordinates" do
    game = games(:one)
    index = 0
    assert_equal 0, game.getCoords(index)[0] #x
    assert_equal 0, game.getCoords(index)[1] #y
    index = 9
    assert_equal 9, game.getCoords(index)[0] #x 
    assert_equal 0, game.getCoords(index)[1] #y
    index = 90
    assert_equal 0, game.getCoords(index)[0] #x
    assert_equal 9, game.getCoords(index)[1] #y
    index = 99
    assert_equal 9, game.getCoords(index)[0] #x
    assert_equal 9, game.getCoords(index)[1] #y
  end

  test "shipPresent correctly returns if ship present on squares" do
    game = games(:one)
    square_no_ship = game.squares.create(index: 0)
    square_ship = game.squares.build(index: 1)
    square_ship.ship_id = ships(:one)
    square_ship.save

    assert game.shipPresent(square_ship.index, "me")
    assert !game.shipPresent(square_no_ship.index, "me")
  end

  test "getStats returns the correct stats" do
    game = games(:one)
    game.createShips
    ship1 = ships(:one)
    ship2 = ships(:two)
    ship3 = ships(:three)

    # Setup some data to send
    # Sink some ships
    sq1 = game.my_ships.find_by_ship_id(ship1)
    sq1.sunk = true
    sq1.save
    sq2 = game.enemy_ships.find_by_ship_id(ship2)
    sq2.sunk = true
    sq2.save
    sq3 = game.enemy_ships.find_by_ship_id(ship3)
    sq3.sunk = true
    sq3.save
    
    game.my_hits = 5
    game.my_misses = 20
    game.enemy_hits = 7
    game.enemy_misses = 18
    game.finished = false

    response = game.getStats("me")
    results = JSON.parse(response)
    assert_equal 5, results["my_hits"]
    assert_equal 20, results["my_misses"] 
    assert_equal ["Carrier"], results["my_sunk_ships"]
    assert_equal false, results["finished"]

    response = game.getStats("enemy")
    results = JSON.parse(response)
    assert_equal 7, results["enemy_hits"]
    assert_equal 18, results["enemy_misses"] 
    assert_equal ["Battleship", "Destroyer"], results["enemy_sunk_ships"].sort!
    assert_equal false, results["finished"]
  end

end