require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  def newPlayer(email)
    Player.new(name: 'Jacob Zuma',
               email: email)
  end

  test "player name, email must not be empty" do
    player = Player.new()
    assert player.invalid?
    assert player.errors[:name].any?
    assert player.errors[:email].any?
  end
  
end
