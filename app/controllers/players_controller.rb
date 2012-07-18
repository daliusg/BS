
class PlayersController < ApplicationController

  # GET /players/new
  # renders new, which renders _form with name/email for submission
  def new
    @player = Player.new

    respond_to do |format|
      format.js { } #new.js.erb
    end
  end

  # POST /players
  # Processes the name/email form filled out
  # Renders 'create', which displays another button to start fleet setup
  def create
    # Find player or create a new one if this one does not exist...
    if params[:player]["name"]=="" || params[:player]["email"]==""
      # Set the player to a generic default, so user can still play
      # without registering
      @player = Player.find_or_create_by_name_and_email(
                                        {name: "Brig. Gen. Jack D. Ripper",
                                         email: "stopworrying@andlove.thebomb" }) 
    else
      # or create/find a player matching the input data
      @player = Player.find_or_create_by_name_and_email(params[:player]) 
    end

    session[:player_id] = @player.id

    respond_to do |format|
        format.js { } # create.js.erb
    end
  end

end
