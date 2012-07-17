class ApplicationController < ActionController::Base
  protect_from_forgery
  # before_filter :register

  private

  def current_game
    Game.find(session[:game_id])
  end

  def current_player
    Player.find(session[:player_id])
  end
  
  def getIndex (x,y)
    return y*10 + x
  end

  def getCoords (index)
    x = index%10
    y = index/10
    return x,y
  end
end
