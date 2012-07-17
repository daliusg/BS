require 'test_helper'

class EnemySquareTest < ActiveSupport::TestCase
  test "enemy_square game_id, index must be set!" do
    enemy_square = EnemySquare.new()
    assert enemy_square.invalid?
    assert enemy_square.errors[:game_id].any?
    assert enemy_square.errors[:index].any?
  end

  test "checkHit returns correct response" do
    assert_equal enemy_squares(:no_ship).checkHit, "miss"
    assert_equal enemy_squares(:ship_not_hit).checkHit, "hit"
    assert_equal enemy_squares(:ship_hit).checkHit, "already_hit"
  end
end
