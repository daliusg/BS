require 'test_helper'

class SquareTest < ActiveSupport::TestCase
  test "square game_id, index must be set!" do
    square = Square.new()
    assert square.invalid?
    assert square.errors[:game_id].any?
    assert square.errors[:index].any?
  end

  test "checkHit returns correct response" do
    assert_equal squares(:no_ship).checkHit, "miss"
    assert_equal squares(:ship_not_hit).checkHit, "hit"
    assert_equal squares(:ship_hit).checkHit, "already_hit"
  end
end
