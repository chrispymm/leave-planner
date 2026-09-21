require "test_helper"

class InvitationAcceptancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invitation = accounts(:pymm_account).invitations.create!(invited_by: users(:chris), email: "new-member@example.com")
  end

  test "shows the accept form for a pending invitation" do
    get accept_invitation_url(@invitation.token)
    assert_response :success
  end

  test "creates a user and membership, and signs them in, when accepted with matching passwords" do
    assert_difference([ "User.count", "Membership.count" ], 1) do
      post accept_invitation_create_url(@invitation.token), params: { password: "password123", password_confirmation: "password123" }
    end

    assert_redirected_to root_path
    @invitation.reload
    assert @invitation.accepted?

    new_user = User.find_by(email_address: "new-member@example.com")
    assert_not_nil new_user
    assert_equal accounts(:pymm_account), new_user.account
  end

  test "rejects mismatched passwords without creating a user" do
    assert_no_difference("User.count") do
      post accept_invitation_create_url(@invitation.token), params: { password: "password123", password_confirmation: "nope" }
    end

    assert_response :unprocessable_entity
  end

  test "an expired invitation cannot be accepted" do
    @invitation.update_column(:expires_at, 1.hour.ago)

    get accept_invitation_url(@invitation.token)
    assert_redirected_to new_session_path

    assert_no_difference("User.count") do
      post accept_invitation_create_url(@invitation.token), params: { password: "password123", password_confirmation: "password123" }
    end
  end

  test "an already-accepted invitation cannot be reused" do
    @invitation.update_column(:accepted_at, Time.current)

    get accept_invitation_url(@invitation.token)
    assert_redirected_to new_session_path
  end

  test "an invalid token shows an error" do
    get accept_invitation_url("not-a-real-token")
    assert_redirected_to new_session_path
  end
end
