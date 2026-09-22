require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "#account returns the user's account via membership" do
    assert_equal accounts(:pymm_account), users(:chris).account
  end

  test "calendar layout defaults to grid" do
    user = User.create!(email_address: "new-user@example.com", password: "password")

    assert_equal "grid", user.calendar_layout
  end

  test "calendar layout must be grid or list" do
    user = users(:chris)

    assert user.update(calendar_layout: "list")
    assert_not user.update(calendar_layout: "invalid")
    assert_includes user.errors[:calendar_layout], "is not included in the list"
  end
end
