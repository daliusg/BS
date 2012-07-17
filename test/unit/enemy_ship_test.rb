require 'test_helper'

class EnemyShipTest < ActiveSupport::TestCase
  test "enemy_ships must have game and ship id's" do
    enemy_ship = EnemyShip.new
    assert enemy_ship.invalid?
    assert enemy_ship.errors[:ship_id].any?
    assert enemy_ship.errors[:game_id].any?
  end
end
