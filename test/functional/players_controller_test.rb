require 'test_helper'

class PlayersControllerTest < ActionController::TestCase
  setup do
    @player = players(:one)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create player" do
    assert_difference('Player.count') do
      post :create, player: { average: @player.average, email: @player.email, losses: @player.losses, name: @player.name, wins: @player.wins }
    end

    assert_redirected_to player_path(assigns(:player))
  end
end
