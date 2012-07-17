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

  test "email must be of the proper format" do
    ok = %w{ this@myemail, that@this.com, good@.onya}
    bad = %w{ thisismyemail, @dot.com, @ }

    ok.each do |email|
      assert newPlayer(email).valid?, "#{email} shouldn't be invalid"
    end

    bad.each do |email|
      assert newPlayer(email).invalid?, "#{email} shouldn't be valid"
    end
  end
  
end
