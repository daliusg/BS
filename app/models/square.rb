class Square < ActiveRecord::Base
  belongs_to :ship
  belongs_to :game

  attr_accessible :index, :ship_id, :game_id, :hit

  # Returns:  ['hit', shipName], ['miss'], or ['already_hit']
  def checkHit 
    if ship_id
      if hit
        return 'already_hit'
      else
        self.hit = true
        self.save
        return 'hit'
      end
    else
      return 'miss'
    end       
  end

end