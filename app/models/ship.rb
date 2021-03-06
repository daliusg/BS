class Ship < ActiveRecord::Base
  has_many :squares
  has_many :enemy_ships
  has_many :my_ships
  
  validates :name, :length, presence: true

  attr_accessible :name, :length
  
end
