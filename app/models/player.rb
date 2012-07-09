class Player < ActiveRecord::Base
  has_many :games, dependent: :destroy

  attr_accessible :name, :email, :wins, :losses, :average
  validates :name, :email, presence: true
  validates :email, format: {
    with: %r{^.+@.+$}i,
    message: 'incorrect email format'
  }
end
