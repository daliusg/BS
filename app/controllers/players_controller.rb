
class PlayersController < ApplicationController

  # GET /players/new
  # GET /players/new.json
  def new
    @player = Player.new

    respond_to do |format|
      format.js { } #new.js.erb
    end
  end

  # POST /players
  # POST /players.json
  def create
    # Find player or Create a new one if this one does not exist...
    
    # This works - comment out for now so don't have to enter info when testing
    # @player = Player.find_or_create_by_name_and_email(params[:player]) 
    
    # Use this line for development
    @player = Player.find(1)
    session[:player_id] = @player.id

    respond_to do |format|
        format.js { } # create.js.erb
    end
  end

end
