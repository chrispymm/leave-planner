require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get edit_profile_url
    assert_redirected_to new_session_path
  end

  test "signed-in user can view their own edit page" do
    sign_in_as(users(:chris))
    get edit_profile_url
    assert_response :success
  end

  test "signed-in user can update their own email address" do
    sign_in_as(users(:chris))

    patch profile_url, params: { user: { email_address: "chris-updated@example.com" } }

    assert_redirected_to edit_account_path
    assert_equal "chris-updated@example.com", users(:chris).reload.email_address
  end

  test "signed-in user can update their own password" do
    sign_in_as(users(:chris))

    patch profile_url, params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } }

    assert_redirected_to edit_account_path
    assert users(:chris).reload.authenticate("newpassword123")
  end

  test "leaves password unchanged when left blank" do
    sign_in_as(users(:chris))
    original_digest = users(:chris).password_digest

    patch profile_url, params: { user: { email_address: users(:chris).email_address, password: "", password_confirmation: "" } }

    assert_redirected_to edit_account_path
    assert_equal original_digest, users(:chris).reload.password_digest
  end
end
