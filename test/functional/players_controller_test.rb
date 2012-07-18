require 'test_helper'

class PlayersControllerTest < ActionController::TestCase
  setup :setup_player

  def setup_player
    @player = players(:the_pres)
  end

  test "brings up name-email form" do
    xhr :get, :new
    assert_response :success
    assert_template :new
    assert_template :_form
  end

  test "finds or creates your player if you enter name/email" do
    xhr :post, :create, player: {name: @player.name, email: @player.email}
    assert_equal @player.name, assigns(:player).name
    assert_equal @player.email, assigns(:player).email
    assert_response :success
    assert_template :create
  end

  test "sets up generic player if you do not enter name/email" do
    xhr :post, :create, player: {name: "", email: ""}
    assert_equal "Brig. Gen. Jack D. Ripper", assigns(:player).name
    assert_equal "stopworrying@andlove.thebomb", assigns(:player).email
    assert_response :success
    assert_template :create
  end

end
