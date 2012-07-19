require 'test_helper'

class GamesControllerTest < ActionController::TestCase
  
  test "should show the index page" do
    get :index
    assert_response :success
    assert_template :index
  end

  test "the index page should be displayed correctly" do 
    get :index 
    assert_select '#banner', 1
    assert_select '#game', 1
    assert_select '#my_stats', 1
    assert_select '#my_board', 1
    assert_select '#enemy_board', 1
    assert_select '#enemy_stats', 1
    assert_select '#messages', 1
    assert_select '#register', 1
    assert_select '#my_messages', 1
    assert_select '#enemy_messages', 1
    assert_select '#register', 1
    assert_select '#register form.button_to', 1
    assert_select '#register form.button_to div .button2', 1
  end

  test "stat divs should contains specific divs for hits, misses, ships" do
    get :index 
    assert_select '#my_stats' do
      assert_select '.hits', 1
      assert_select '.misses', 1
      assert_select '.sunk', 1
    end
    assert_select '#enemy_stats' do
      assert_select '.hits', 1
      assert_select '.misses', 1
      assert_select '.sunk', 1
    end
  end

  test "the boards are primed to be set up by js correctly" do
    get :index
    assert_select '#my_board' do
      assert_select '.board', 1
      assert_select '#ships', 1
    end
    
    assert_select '#enemy_board' do
      assert_select '.board', 1
      assert_select '#targets', 1
    end
  end

  test "first time through setup" do
    player = players(:the_pres)
    # No params are sent with this ajax call to setup
    xhr :post, :setup, nil, {player_id: player.id }
    assert_equal 'start', session[:ship_setup_state]
    assert_equal 0, session[:ship_setup_id]
    assert_equal player.name, assigns(:player).name
    assert_equal 'Carrier', assigns(:ship)[0]
    assert_equal 'bow', assigns(:shipFlag)
    assert_equal false, assigns(:redo)
    assert_response :success
    assert_template :setup
  end

  def setup_game_squares_create_ships
    @game = games(:one)
    @game.setupSquares
    @game.createShips
  end

  test "setup processes proper bow placement for first ship" do
    # assume empty board, so any placement is fine
    setup_game_squares_create_ships
    xhr :post, :setup, 
        {x: 7, y: 6,   #params passed with post
         task: "bow"}, 
        {ship_setup_id: 0, game_id: @game.id}   #session id's
    assert_equal 'bow', session[:ship_setup_state]
    assert_equal 'Carrier', assigns(:ship)[0]
    assert_equal false, assigns(:redo)
    assert_equal [67], session[:ship_coords]
    assert_equal 'direction', assigns(:shipFlag)
    assert_response :success
    assert_template :setup
  end

  test "setup processes proper bow placement for ship of length=1" do
    setup_game_squares_create_ships
    xhr :post, :setup, 
        {x: 7, y: 6,   #params passed with post
         task: "bow"}, 
        {ship_setup_id: 6, game_id: @game.id}   #session id's 
    assert_equal 'bow', session[:ship_setup_state]
    assert_equal 'Patrol 2', assigns(:ship)[0]
    assert_equal false, assigns(:redo)
    assert_equal [67], session[:ship_coords]
    assert_equal 'place', assigns(:shipFlag)
    assert_response :success
    assert_template :setup
  end
  
  def place_carrier_0_4
    # place the carrrier in indexes 0-4
    ship = ships(:one)
    @game.placeShip(ship, [0,1,2,3,4], "me")
  end

  test "setup processes invalid bow placement" do
     # assume empty board, so any placement is fine
    setup_game_squares_create_ships
    place_carrier_0_4
    xhr :post, :setup, 
        {x: 0, y: 0,   #params passed with post
         task: "bow"}, 
         #session id's at the start of the request
        {ship_setup_id: 1, game_id: @game.id}   
    assert_equal 'bow', session[:ship_setup_state]
    assert_equal 'Battleship', assigns(:ship)[0]
    assert_equal true, assigns(:redo)
    assert_equal 'bow', assigns(:shipFlag)
    assert_response :success
    assert_template :setup
  end

  test "setup processes proper direction" do
    # assume empty board, so any placement is fine
    setup_game_squares_create_ships
    xhr :post, :setup, 
        {x: 7, y: 0,   #params passed with post
         task: "direction"}, 
         #session id's at the start of the request
        {ship_setup_id: 0, game_id: @game.id, ship_coords: [0]}   
    assert_equal 'direction', session[:ship_setup_state]
    assert_equal 'Carrier', assigns(:ship)[0]
    assert_equal false, assigns(:redo)
    assert_equal 'place', assigns(:shipFlag)
    assert @game.shipPresent(0, "me")
    assert @game.shipPresent(1, "me")
    assert @game.shipPresent(2, "me")
    assert @game.shipPresent(3, "me")
    assert @game.shipPresent(4, "me")
    assert_response :success
    assert_template :setup
  end

  test "setup processes invalid direction" do
    # assume empty board, so any placement is fine
    setup_game_squares_create_ships
    xhr :post, :setup, 
        {x: 9, y: 9,   #params passed with post
         task: "direction"}, 
         #session id's at the start of the request
        {ship_setup_id: 0, game_id: @game.id, ship_coords: [0]}   
    assert_equal 'direction', session[:ship_setup_state]
    assert_equal 'Carrier', assigns(:ship)[0]
    assert_equal true, assigns(:redo)
    assert_equal 'bow', assigns(:shipFlag)
    assert_response :success
    assert_template :setup
  end

  test "setup processes direction would place ship on top of another" do
    # assume empty board, so any placement is fine
    setup_game_squares_create_ships
    place_carrier_0_4
    xhr :post, :setup, 
        {x: 0, y: 2,   #params passed with post
         task: "direction"}, 
         #session id's at the start of the request
        {ship_setup_id: 1, game_id: @game.id, ship_coords: [30]}   
    assert_equal 'direction', session[:ship_setup_state]
    assert_equal 'Battleship', assigns(:ship)[0]
    assert_equal true, assigns(:redo)
    assert_equal 'bow', assigns(:shipFlag)
    assert_response :success
    assert_template :setup
  end

  test "setup processes direction would place ship off the board" do
    # assume empty board, so any placement is fine
    setup_game_squares_create_ships
    xhr :post, :setup, 
        {x: 0, y: 0,   #params passed with post
         task: "direction"}, 
         #session id's at the start of the request
        {ship_setup_id: 0, game_id: @game.id, ship_coords: [2]}   
    assert_equal 'direction', session[:ship_setup_state]
    assert_equal 'Carrier', assigns(:ship)[0]
    assert_equal true, assigns(:redo)
    assert_equal 'bow', assigns(:shipFlag)
    assert_response :success
    assert_template :setup
  end

  test "setup starts processesing next ship when previous one placed" do
    # assume empty board, so any placement is fine
    setup_game_squares_create_ships
    xhr :post, :setup, 
        {task: "placed"},   #params passed with post
         #session id's at the start of the request
        {ship_setup_id: 0, game_id: @game.id}   
    assert_equal 1, session[:ship_setup_id]
    assert_equal 'start', session[:ship_setup_state]
    assert_equal 'Battleship', assigns(:ship)[0]
    assert_equal false, assigns(:redo)
    assert_equal 'bow', assigns(:shipFlag)
    assert_response :success
    assert_template :setup
  end

    test "setup renders setup_last when all ships have been placed" do
    # assume empty board, so any placement is fine
    setup_game_squares_create_ships
    xhr :post, :setup, 
        {task: "placed"},   #params passed with post
         #session id's at the start of the request
        {ship_setup_id: 6, game_id: @game.id}   
    assert_equal 6, session[:ship_setup_id]
    assert_equal 'all_placed', session[:ship_setup_state]
    assert_response :success
    assert_template :setup_last
  end

  def place_all_my_ships
    ship1 = ships(:one)
    @game.placeShip(ship1, [0,1,2,3,4], "me")
    ship2 = ships(:two)
    @game.placeShip(ship2, [20,21,22,23], "me")
    ship3 = ships(:three)
    @game.placeShip(ship3, [40,41,42], "me")
    ship4 = ships(:four)
    @game.placeShip(ship4, [60,61], "me")
    ship5 = ships(:five)
    @game.placeShip(ship5, [80,81], "me")
    ship6 = ships(:six)
    @game.placeShip(ship6, [79], "me")
    ship7 = ships(:seven)
    @game.placeShip(ship7, [99], "me")
  end

  test "start registers player and renders 'start', p45 not working" do
    setup_game_squares_create_ships
    place_all_my_ships
    xhr :post, :start, nil, 
        {game_id: @game.id, 
          player_id: players(:the_pres).id,
         p45_WORKING: false}
    assert_equal 200, assigns(:code) 
    assert_equal "OK", assigns(:message) 
    assert_equal false, assigns(:p45_id).nil?
    my_parsed_stats = JSON.parse(assigns(:myStats))
    enemy_parsed_stats = JSON.parse(assigns(:enemyStats))
    assert_equal 0, my_parsed_stats["my_hits"]
    assert_equal 0, my_parsed_stats["my_misses"]
    assert_equal [], my_parsed_stats["my_sunk_ships"]
    assert_equal false, my_parsed_stats["finished"]
    assert_equal 0, enemy_parsed_stats["enemy_hits"]
    assert_equal 0, enemy_parsed_stats["enemy_misses"]
    assert_equal [], enemy_parsed_stats["enemy_sunk_ships"]
    assert_equal false, enemy_parsed_stats["finished"]
    assert_response :success
    assert_template :start
  end

  test "start registers player and renders 'start', p45 working" do
    setup_game_squares_create_ships
    place_all_my_ships
    xhr :post, :start, nil, 
        {game_id: @game.id, 
          player_id: players(:the_pres).id,
         p45_WORKING: true}
    assert_equal 200, assigns(:code) 
    assert_equal "OK", assigns(:message) 
    assert_equal false, assigns(:p45_id).nil?
    my_parsed_stats = JSON.parse(assigns(:myStats))
    enemy_parsed_stats = JSON.parse(assigns(:enemyStats))
    assert_equal 0, my_parsed_stats["my_hits"]
    assert_equal 0, my_parsed_stats["my_misses"]
    assert_equal [], my_parsed_stats["my_sunk_ships"]
    assert_equal false, my_parsed_stats["finished"]
    assert_equal 0, enemy_parsed_stats["enemy_hits"]
    assert_equal 0, enemy_parsed_stats["enemy_misses"]
    assert_equal [], enemy_parsed_stats["enemy_sunk_ships"]
    assert_equal false, enemy_parsed_stats["finished"]
    assert_response :success
    assert_template :start
  end

  test "attack doesn't allow firing if it's not your turn" do
    @game = games(:one)
    @game.my_turn = false
    @game.save
    xhr :post, :attack, {x: 4, y: 6}, {game_id: @game.id}
    assert_response :success
    assert_equal "$('#enemy_messages').html"+
      "(\"<p>Tsk, tsk, tsk...  Wait your turn!</p>\");", @response.body
  end

  test "attack processes firing a hit correctly when playing against own enemy" do
    setup_game_squares_create_ships
    @game.setupEnemyBoard
    @game.start
    ship = ships(:one)
    square = @game.enemy_squares.find_by_ship_id(ship)
    index = square.index
    x, y = @game.getCoords(index)
    xhr :post, :attack, {x: x, y: y}, {game_id: @game, p45_WORKING: false}
    enemy_parsed_results = JSON.parse(assigns(:result))
    assert_equal "hit", enemy_parsed_results["status"]
    enemy_parsed_stats = JSON.parse(assigns(:stats))
    assert_equal 1, enemy_parsed_stats["enemy_hits"]
    assert_equal 0, enemy_parsed_stats["enemy_misses"]
    assert_equal [], enemy_parsed_stats["enemy_sunk_ships"]
    assert_equal false, enemy_parsed_stats["finished"]
    assert_response :success
  end


  def sink_all_but_enemy_patrol2
    ship = ships(:seven)
    enemy_ships = @game.enemy_squares.where("ship_id IS NOT NULL").all
    last_ship = @game.enemy_squares.where(ship_id: ship).first
    enemy_ships.delete(last_ship)
    # Now we have an array of all squares where all ships (except patrol 2) are
    # 'last_ship' is a ship of length 1 that will be sunk last
    enemy_ships.each do |eShip|
      x, y = @game.getCoords(eShip.index)
      @game.fire(x, y, "enemy")
    end
    return last_ship

  end
  test "attack processes enemy loss correctly when playing against own enemy" do
    setup_game_squares_create_ships
    @game.setupEnemyBoard # This places ships on the enemy board
    last_ship = sink_all_but_enemy_patrol2
    @game.start
    index = last_ship.index
    x, y = @game.getCoords(index)
    xhr :post, :attack, {x: x, y: y}, {game_id: @game, p45_WORKING: false}
    enemy_parsed_results = JSON.parse(assigns(:result))
    assert_equal "hit", enemy_parsed_results["status"]
    assert_equal "Patrol 2", enemy_parsed_results["sunk"]
    assert_equal "lost", enemy_parsed_results["game_status"]

    enemy_parsed_stats = JSON.parse(assigns(:stats))
    assert_equal 18, enemy_parsed_stats["enemy_hits"]
    assert_equal 0, enemy_parsed_stats["enemy_misses"]
    assert_equal ["Battleship","Carrier","Destroyer","Patrol 1","Patrol 2",
                  "Submarine 1","Submarine 2"],
                   enemy_parsed_stats["enemy_sunk_ships"].sort!
    assert_equal true, enemy_parsed_stats["finished"]
    assert_response :success
  end

  def register_player
    player = players(:the_pres)
    uri = URI('http://battle.platform45.com/register')
    request = Net::HTTP::Post.new(uri.path)
    request.content_type = 'application/json'
    body = { name: player.name, email: player.email}
    request.body = JSON(body)
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    r_body = response.body
    r_JSON = JSON.parse(r_body)
    p45_id = r_JSON["id"].to_i
    @game.botID = p45_id
    @game.save
  end

  test "attack processes firing correctly when playing against p45" do
    setup_game_squares_create_ships
    @game.start
    register_player
    xhr :post, :attack, {x: 1, y: 1}, {game_id: @game, p45_WORKING: true}
    enemy_parsed_results = JSON.parse(assigns(:result).body)
    # status = enemy_parsed_results["status"]
    assert_equal true, ["hit","miss"].include?(enemy_parsed_results["status"])
    enemy_parsed_stats = JSON.parse(assigns(:stats))
    if enemy_parsed_results["status"] == "hit"
      assert_equal 1, enemy_parsed_stats["enemy_hits"]
    elsif enemy_parsed_results["status"] =="miss"
      assert_equal 1, enemy_parsed_stats["enemy_misses"]
    end
    assert_equal [], enemy_parsed_stats["enemy_sunk_ships"]
    assert_equal false, enemy_parsed_stats["finished"]
    assert_response :success
  end

  test "enemy fire processes fire correctly, playing against own enemy" do
    setup_game_squares_create_ships
    place_all_my_ships
    @game.my_turn = false
    @game.save
    xhr :get, :enemyFire, nil, {game_id: @game, p45_WORKING: false}
    parsed_results = JSON.parse(assigns(:result))
    assert_equal true, ["hit","miss"].include?(parsed_results["status"])
    parsed_stats = JSON.parse(assigns(:stats))
    if parsed_results["status"] == "hit"
      assert_equal 1, parsed_stats["my_hits"]
    elsif parsed_results["status"] =="miss"
      assert_equal 1, parsed_stats["my_misses"]
    end
    assert_equal [], parsed_stats["my_sunk_ships"]
    assert_equal false, parsed_stats["finished"]
    assert_response :success
    assert_template :enemyFire
  end
  
end
