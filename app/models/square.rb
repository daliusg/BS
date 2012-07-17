class Square < ActiveRecord::Base
  belongs_to :ship
  belongs_to :game

  attr_accessible :index, :ship_id, :game_id, :hit

  validates :game_id, :index, presence: true

  # Returns:  'hit', 'miss', or 'already_hit'
  def checkHit 
    if !self.ship_id.blank?
      if self.hit == true
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