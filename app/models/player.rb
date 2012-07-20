class Player < ActiveRecord::Base
  has_many :games, dependent: :destroy

  attr_accessible :name, :email, :wins, :losses, :average
  validates :name, :email, presence: true
  
end
