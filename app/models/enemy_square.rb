class EnemySquare < ActiveRecord::Base
  belongs_to :ship
  belongs_to :game

  attr_accessible :index, :ship_id, :game_id, :hit
  
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
