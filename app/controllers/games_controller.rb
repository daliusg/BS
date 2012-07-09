
class GamesController < ApplicationController
  # before_filter :register
  require "net/http"

  def index
    # TODO: Add logic to check if user has come back to existing game
    #       and accomodate for setting up game wherever they need to be?
    session[:debug] = true
    respond_to do |format|
        format.html { } #index.html.erb
      end
  end
  
  # POST/setup
  def setup
    # Change which ship is being set up with each visit to 'setup'
    # :ship_setup_id identifies which ship we're working with a the moment
    # :ship_setup_state identifies which activity we'll be performing =>
    #     start: first time through for this ship, prompt user to place bow
    #     bow: user has clicked to place bow, validate and either reprompt or
    #          and proceed to prompt for the direction
    #     direction: user has clicked to determine direction of placement
    #              validate and either reprompt or proceed with placing ship 
    #              (update model and call javascript to mark board accordingly)
    #     placed: use this as a marker to denote that the ship has been placed
    
    # Capture param being sent from client
    if !params[:task]
      # First time through the setup process, set this variable
      session[:ship_setup_state] = 'start'
    else
      session[:ship_setup_state] = params[:task]
    end

    # First time through, select first ship (ship_setup_id=0 - different than
    # actual DB id)
    if !session[:ship_setup_id]
      session[:ship_setup_id] = 0
    # Once the previous ship's state is 'placed', select next one and reset
    # state to 'start
    elsif session[:ship_setup_id] < 6  &&  session[:ship_setup_state] == 'placed'
      session[:ship_setup_id] += 1
      session[:ship_setup_state] = 'start'
    elsif session[:ship_setup_id] == 6  &&  session[:ship_setup_state] == 'placed'
      session[:ship_setup_state] = 'all_placed'
    end

    # Create a game if one has not been created yet (1st time through 'setup')
    # :game_id is the game object's ID number in the DB, not the same as P45_ID
    if !session[:game_id]
      # Create game and link to current player
      player = current_player
      game = player.games.create()
      session[:game_id] = game.id
      # Have model set up 100 squares for this game
      game.setupSquares 
    else
      game = Game.find(session[:game_id])
    end  

    # Obtain the name & length of the ship we are setting up
    ships = Ship.find(:all, :select => "name, length", :order => "id")
    ships = ships.map { |s| [s.name, s.length] }  #An array of all ships
    @ship = ships[session[:ship_setup_id]]    #[name,length] of current ship
    @shipID = session[:ship_setup_id]
    @gameID = session[:game_id]
    @state = session[:ship_setup_state]

    # The first time through for each ship, set shipFlag to "bow" to 
    # trigger the javascript to execute bow placement prompt 
    if session[:ship_setup_state] == 'start'
      @shipFlag = 'bow'
      @redo = false

    # The user clicked to place bow - must validate the selection, if not
    # valid, must reprompt to place bow
    # If valid, then store this data (model?, session?) and prompt for direction
    elsif session[:ship_setup_state] == 'bow'
      # Validate if this is OK location by checking if currently occupied
      x = params[:x].to_i
      y = params[:y].to_i
      index = getIndex(x,y)
      square = game.squares.find_by_index(index)

      if square.ship_id
        @redo = true
      else
        @redo = false
        #store x,y coords of bow
        session[:ship_coords] = [getIndex(x,y)]
        # settingetCoords(session[:ship_coords][0])will cause JS to prompt for ship direction
        if @ship[1] == 1  #special case of ship being 1 unit long -> place it!
          @shipFlag = 'place'
        else  
          @shipFlag = 'direction'
        end
      end

    # The user clicked to determine direction - must validate the selection, 
    # if not valid, must reprompt for direction
    # If valid, then "place" ship in the model, and ask JS to place on screen
    elsif session[:ship_setup_state] == 'direction'
      # Validate if this is OK location by checking if currently occupied
      x = params[:x].to_i
      y = params[:y].to_i
      bowX = getCoords(session[:ship_coords][0])[0]
      bowY = getCoords(session[:ship_coords][0])[1]
      length = @ship[1]
      valid = true

      for index in (1...length)
        if valid == true 
          # First get X,Y coordinates of next placement
          if bowX == x         # ship lies N or S
            if bowY < y        # ship lies S
              y = bowY + index
            else # bowY > y    # ship lies N
              y = bowY - index
            end
          elsif bowY == y      # ship lies E or W
            if bowX < x        # ship lies E
              x = bowX + index
            else # bowX > x    # ship lies W
              x = bowX - index
            end
          else #direction picked not in N,E,S,W directions, redo!
            valid = false
          end

          # Out-of-bounds check
          if x < 0 || x > 9 || y < 0 || y > 9 
            valid = false
          end

          if valid
            # append these [x,y] coordinates to :ship_coords sessions variable
            session[:ship_coords] << getIndex(x,y)
            square = game.squares.find_by_index(getIndex(x,y))
            # If there's already a ship there, invalidate this placement
            if square.ship_id
              valid = false
            end
          end
        end
      end    

      # If arrive here and 'valid' false, restart from placing bow
      if !valid
        session[:ship_coords] = nil
        @redo = true
        @shipFlag = 'bow'

      # if valid=true, OK to place ship
      else
        # Have the model record the position of the ship
        game.placeShip(session[:ship_setup_id]+1, session[:ship_coords])
        # setting state to 'place' will cause JS to mark ship on board
        @redo = false
        @shipFlag = 'place'
      end  

    # Once all else has been done, last step is to register game with P45 Bot
    # and start nuking away!  
    else # session[:ship_setup_state] == 'all_placed'
      # result = register(current_player)
      # logger.info("")
      
      respond_to do |format|
        format.js { render 'setup_last' } # prompt for the games to begin
      end
    end

    respond_to do |format|
        format.js { } #setup.js.erb
    end
  end

  # POST /create
  def start
    # register current player with P45 Bot
    # Battleship Bot is supposed to return id, x, & y coordinates of first fire
    result = register(current_player)

    code = result.code
    message = result.message
    r_body = result.body
    r_JSON = JSON.parse(r_body)
    
    p45_id = r_JSON["id"]
    xCoord = r_JSON["x"]
    yCoord = r_JSON["y"]

    logger.info("============Results sent back from P45 ============")
    logger.info("code: #{code}")
    logger.info("message: #{message}")
    logger.info("p45id: #{p45_id}")
    logger.info("x: #{xCoord}")
    logger.info("y: #{yCoord}")
    logger.info("===================================================")
    
    # Check for proper response & correct information sent back
    # and save p45 Bot's game id 
    if code == 200 && p45_id && xCoord && yCoord
      game = Game.find(session[:game_id])
      game.botID = p45_id
      game.save
      
      # Registration successful, game starts, process p45 shot and proceed
      index = getIndex(xCoord, yCoord)
      ###################   TODO:   ###########################################
      # game.firedUpon(index)

      respond_to do |format|
        format.js { } # start.js.erb 
      end
    
    # Registration failure
    else
      respond_to do |format|
        format.js { render 'reg_fail'} 
      end    
    end

  end

  
  # POST /attack
  # This method is seriously messed up, needs to be updated with new flow/logic
  def attack
    # There is a unique case when the game has not started yet and the user
    # starts firing missiles by clicking on the enemy board. If this happens
    # ignore the AJAX requests coming in, redirect to index
    if !session[:ok_to_fire]
      respond_to do |format|
        format.js { } #attack.js.erb
      end
    end  
    # X & Y coordinates are sent from the client 
    # they need to be passed on to Battleship Bot server as a NUKE request
    @xCoord = params[:x]
    @yCoord = params[:y]

    #Nuke request to Battleship Bot

    respond_to do |format|
      format.js { }
      # format.json { hurl artilery at P45 server }
    end
  end

  private
    
    # This method registers the player with the P45 Bot, returs the JSON response
    def register(player)
      uri = URI('http://battle.platform45.com/register')
      request = Net::HTTP::Post.new(uri.path)
      request.content_type = 'application/json'
      body = { name: player.name, email: player.email}
      request.body = JSON(body)
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end
    end

end
