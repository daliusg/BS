
class GamesController < ApplicationController
  # before_filter :register
  require "net/http"
  P45_WORKING = false

  def index
    # TODO: Add logic to check if user has come back to existing game
    #       and accomodate for setting up game wherever they need to be?
    reset_session
    respond_to do |format|
      format.html { } #index.html.erb
    end
  end
  
  # POST/setup
  def setup
    # This method is called many times during the ship setup process.  It 
    # determines what prompts to display to the user, and validates each 
    # placement the user tries to make. Only if a ship's placement is valid
    # is it commited to the db. Once all ships are successfully placed, this
    # this method is finished and will then render "setup_last" to prompt
    # the user to start the game.
    #################       Some session vars used  ###########################
    # :ship_setup_id - identifies which ship we're working with a the moment
    # :ship_setup_state - identifies which activity we'll be performing =>
    #     start: first time through for this ship, prompt user to place bow
    #     bow: user has clicked to place bow, validate and either reprompt or
    #          and proceed to prompt for the direction
    #     direction: user has clicked to determine direction of placement
    #              validate and either reprompt or proceed with placing ship 
    #              (update model and call javascript to mark board accordingly)
    #     placed: use this as a marker to denote that the ship has been placed
    # :game_id - our game id in the db
    # :ship_coords - stores ship's coordinates before they are validated and
    #                written to db
    
    # Capture param being sent from client
    if !params[:task]
      # First time through the setup process, set this variable
      session[:ship_setup_state] = 'start'
      session[:game_id] = nil
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
      game.createShips
    else
      game = current_game
    end  

    # Obtain the name & length of the ship we are setting up
    ships = Ship.find(:all, :select => "name, length", :order => "id")
    ships = ships.map { |s| [s.name, s.length] }  #An array of all ships
    @ship = ships[session[:ship_setup_id]]   #[name,length] of current ship

    # The first time through for each ship, set shipFlag to "bow" to 
    # trigger the javascript to execute bow placement prompt 
    if session[:ship_setup_state] == 'start'
      @shipFlag = 'bow'
      @redo = false

    # The user clicked to place bow - must validate the selection, if not
    # valid, must reprompt to place bow
    # If valid, then store this data in :ship_coords and prompt for direction
    elsif session[:ship_setup_state] == 'bow'
      # Validate if this is OK location by checking if currently occupied
      x = params[:x].to_i
      y = params[:y].to_i
      index = getIndex(x,y)
      square = game.squares.find_by_index(index)

      logger.debug("square: #{square.inspect}")

      if square.ship_id # ship already present
        @redo = true
      else
        @redo = false
        #store x,y coords of bow
        session[:ship_coords] = [getIndex(x,y)]
        # set flags to prompt client script to either place 1 unit ship or
        # prompt for direction
        if @ship[1] == 1  #if length is 1, go ahead and place the ship!
          game.placeShip(session[:ship_setup_id]+1, session[:ship_coords], "me")
          @shipFlag = 'place'
        else  
          @shipFlag = 'direction'
        end
      end

    # The user clicked to determine direction - must validate the selection, 
    # if not valid, must reprompt for direction
    # If valid, then "place" ship in the model, and ask client JS to display
    elsif session[:ship_setup_state] == 'direction'
      # Validate if this is OK location by checking if currently occupied
      x = params[:x].to_i
      y = params[:y].to_i
      coords = session[:ship_coords] #currently just [bowIndex]
      length = @ship[1]

      # valid = true
      direction = getDirection(coords, x, y) # Determines N,S,E,W
      if direction <= 3
        valid = game.placementClear(length, direction, coords, "me")
      else  #user's click not in cardinal direction
        valid = false
      end         

      # If valid == false, restart from placing bow
      if !valid
        session[:ship_coords] = nil
        @redo = true
        @shipFlag = 'bow'

      # if valid=true, OK to place ship
      else
        # Have the model record the position of the ship
        game.placeShip(session[:ship_setup_id]+1, coords, "me")
        # setting state to 'place' will cause JS to mark ship on board
        @redo = false
        @shipFlag = 'place'
      end  

    else # session[:ship_setup_state] == 'all_placed' 
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
    game = Game.find(session[:game_id])
    if P45_WORKING
      result = register(current_player)
      
      code = result.code.to_i
      message = result.message
      r_body = result.body
      r_JSON = JSON.parse(r_body)

      p45_id = r_JSON["id"].to_i
      x = r_JSON["x"].to_i #careful: this will turn nil into a 0!
      y = r_JSON["y"].to_i # !!

      logger.info("============Results sent back from P45 ============")
      logger.info("code: #{code}")
      logger.info("message: #{message}")
      logger.info("p45id: #{p45_id}")
      logger.info("x: #{x}")
      logger.info("y: #{y}")
      logger.info("===================================================")
    end

    if !P45_WORKING
      x, y = getRandomFire       
      code = 200
      p45_id = 101101
    end
    
    # Check for proper response & correct information sent back
    # and save p45 Bot's game id 
    if code == 200 && p45_id && x && y
      game.botID = p45_id
      if !P45_WORKING
        game.setupEnemyBoard   ### THIS WILL SET UP RANDOM ENEMY BOARD
      end
      game.start
      game.save
      @index = getIndex(x, y)
      # MAIN METHOD TO PROCESS ENEMY FIRE
      @result = game.fire(x, y, "me")

      @myStats = game.getStats("me")  # Statistics pertaining to me
      @enemyStats = game.getStats("enemy")  # enemy stats

      respond_to do |format|
        format.js { } # start.js.erb 
      end

    else  # Registration failure
      respond_to do |format|
        format.js { render 'reg_fail'} 
      end    
    end

  end
  
  # POST /attack
  # This method processes a user initiated attack on P45
  def attack
    # There is a unique case when the game has not started yet and the user
    # starts firing missiles by clicking on the enemy board. If this happens
    # ignore the AJAX requests coming in, redirect to index
    if session[:game_id]
      game = current_game
      if !game.finished && game.my_turn  
        # X & Y coordinates are sent from the client 
        # they need to be passed on to Battleship Bot server as a NUKE request
        x = params[:x].to_i
        y = params[:y].to_i

        if P45_WORKING   ##############   ONLY DO THIS IF SERVER WORKING ##########
          @result = fire(game.botID, x, y)
          
          # For debugging and seeing what P45 is sending back...
          code = result.code.to_i
          message = result.message
          r_body = result.body
          r_JSON = JSON.parse(r_body)

          status = r_JSON["status"]  # hit or miss
          sunk = r_JSON["sunk"] # name of craft which was sunk
          game_status = r_JSON["game_status"] #'lost' when game is lost
          error = r_JSON["error"] # Error message if something went wrong
          prize = r_JSON["prize"]# Will contain prize when sunk all enemy ships
          nextX = r_JSON["x"] # I assume this will contain the next x coordinate fired?
          nextY = r_JSON["y"] # I assume this will contain the next y coordinate fired?
          logger.debug("status #{status}")
          logger.debug("sunk #{sunk}")
          logger.debug("game_status #{game_status}")
          logger.debug("error #{error}")
          logger.debug("prize #{prize}")    
          logger.debug("nextX: #{nextX}")
          logger.debug("nextY: #{nextY}")
          # If P45 does indeed send it's next firing, store it in session vars 
          if !nextX.nil? && !nextY.nil?
            session[:nextX] = nextX
            session[:nextY] = nextY
          end
        
        ################     PLAY MY OWN SIMULATED ENEMY                ###########
        else
          @index = getIndex(x,y)
          @result = game.fire(x, y, "enemy") 
          if !JSON.parse(@result)["game_status"].nil? then @lost=true end
        end

        @stats = game.getStats("enemy")  # Hash of enemy's stats .to_json
        
        if game.finished
          reset_session
        end
        respond_to do |format|
          format.js { } #attack.js.erb
        end
      else
        if !game.finished && !game.my_turn
          respond_to do |format|
            format.js { 
              render js: 
                "$('#enemy_messages').html(\"<p>Tsk, tsk, tsk...  Wait your turn!</p>\");"}
          end
        else # Game is finished
          reset_session
          respond_to do |format|
           format.js { redirect_to games_url } 
          end
        end
      end
    else  
      reset_session
      respond_to do |format|
        format.js { render(:index) { |page| page.redirect_to games_url }}
        # format.js { redirect_to games_url } 
      end
    end
  end

  # Handles enemy firing
  def enemyFire
    game = current_game
    if !game.my_turn
      if P45_WORKING
        x = session[:nextX]
        y = session[:nextY]
      else # !P45_WORKING
        x, y = getRandomFire
        logger.debug("x,y returned from getRandomFire:  #{x}, #{y}")
        # x = rand(10)
        # y = rand(10)
      end
      
      @index = getIndex(x,y)
      # MAIN METHOD TO PROCESS ENEMY FIRE
      @result = game.fire(x, y, "me")
      # Returns a big hash of all stats
      @stats = game.getStats("me")

      respond_to do |format|
        format.js { } # enemyFire.js.erb 
      end
    else
      respond_to do |format|
        format.js {  } 
      end
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

    def fire (p45ID, x, y)
      uri = URI('http://battle.platform45.com/nuke')
      request = Net::HTTP::Post.new(uri.path)
      request.content_type = 'application/json'
      body = {id: p45ID, x: x, y: y}  
      request.body = JSON(body)
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end
    end

    def getDirection (coords, x, y)
      bowX = getCoords(coords[0])[0]
      bowY = getCoords(coords[0])[1]
      if bowX == x         # ship lies N or S
        if bowY > y        # ship lies N
          direction =  0
        else               # ship lies S
          direction =  1
        end
      elsif bowY == y      # ship lies E or W
        if bowX < x        # ship lies E
          direction =  2
        else               # ship lies W
          direction =  3
        end
      end
      return direction
    end

    def getRandomFire
    session[:enemyNotFired] ||= (0..99).to_a
    session[:enemyFired] ||= []
    arrIndex = rand(session[:enemyNotFired].length)
    fireIndex = session[:enemyNotFired].delete_at(arrIndex)
    session[:enemyFired] << fireIndex
    return getCoords(fireIndex)
  end
end