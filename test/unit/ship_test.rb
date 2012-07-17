require 'test_helper'

class ShipTest < ActiveSupport::TestCase
  test "ship attributes must not be empty" do
    ship = Ship.new
    assert ship.invalid?
    assert ship.errors[:name].any?
    assert ship.errors[:length].any?
  end
end
