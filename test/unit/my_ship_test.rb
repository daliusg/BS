require 'test_helper'

class MyShipTest < ActiveSupport::TestCase
  test "my_ships must have game and ship id's" do
    my_ship = MyShip.new
    assert my_ship.invalid?
    assert my_ship.errors[:ship_id].any?
    assert my_ship.errors[:game_id].any?
  end
end
