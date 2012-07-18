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

  def setup_game_and_boards
    @game = games(:one)
    @game.setupSquares
    @game.createShips
  end

  test "setup processes proper bow placement for first ship" do
    # assume empty board, so any placement is fine
    setup_game_and_boards
    xhr :post, :setup, 
        {"x"=>"7", "y"=>"6",   #params passed with post
         "task"=>"bow"}, 
        {ship_setup_id: 0, game_id: @game.id}   #session id's at the start of the request
    assert_equal 'bow', session[:ship_setup_state]
    assert_equal 'Carrier', assigns(:ship)[0]
    assert_equal false, assigns(:redo)
    assert_equal [67], session[:ship_coords]
    assert_equal 'direction', assigns(:shipFlag)
    assert_response :success
    assert_template :setup
  end

  test "setup processes proper bow placement for ship of length=1" do
    setup_game_and_boards
    xhr :post, :setup, 
        {"x"=>"7", "y"=>"6",   #params passed with post
         "task"=>"bow"}, 
        {ship_setup_id: 6, game_id: @game.id}   #session id's at the start of the request
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
    setup_game_and_boards
    place_carrier_0_4
    xhr :post, :setup, 
        {"x"=>"0", "y"=>"0",   #params passed with post
         "task"=>"bow"}, 
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
    setup_game_and_boards
    xhr :post, :setup, 
        {"x"=>"7", "y"=>"0",   #params passed with post
         "task"=>"direction"}, 
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
    setup_game_and_boards
    xhr :post, :setup, 
        {"x"=>"9", "y"=>"9",   #params passed with post
         "task"=>"direction"}, 
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
    setup_game_and_boards
    place_carrier_0_4
    xhr :post, :setup, 
        {"x"=>"0", "y"=>"2",   #params passed with post
         "task"=>"direction"}, 
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
    setup_game_and_boards
    xhr :post, :setup, 
        {"x"=>"0", "y"=>"0",   #params passed with post
         "task"=>"direction"}, 
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
    setup_game_and_boards
    xhr :post, :setup, 
        {"task"=>"placed"},   #params passed with post
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
    setup_game_and_boards
    xhr :post, :setup, 
        {"task"=>"placed"},   #params passed with post
         #session id's at the start of the request
        {ship_setup_id: 6, game_id: @game.id}   
    assert_equal 6, session[:ship_setup_id]
    assert_equal 'all_placed', session[:ship_setup_state]
    assert_response :success
    assert_template :setup_last
  end

  

end
