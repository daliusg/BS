class Ship < ActiveRecord::Base
  has_many :squares
  attr_accessible :name, :length

end
