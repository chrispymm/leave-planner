require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:chris))
  end

  test "should get new" do
    get new_account_invitation_url
    assert_response :success
  end

  test "any member can create an invitation" do
    sign_in_as(users(:jess))

    assert_difference("Invitation.count", 1) do
      post account_invitations_url, params: { invitation: { email: "newperson@example.com" } }
    end

    assert_redirected_to edit_account_path
    invitation = Invitation.order(:created_at).last
    assert_equal "newperson@example.com", invitation.email
    assert_equal users(:jess), invitation.invited_by
  end

  test "rejects invalid invitation" do
    assert_no_difference("Invitation.count") do
      post account_invitations_url, params: { invitation: { email: users(:jess).email_address } }
    end

    assert_response :unprocessable_entity
  end

  test "can cancel a pending invitation" do
    invitation = accounts(:pymm_account).invitations.create!(invited_by: users(:chris), email: "cancel-me@example.com")

    assert_difference("Invitation.count", -1) do
      delete account_invitation_url(invitation)
    end

    assert_redirected_to edit_account_path
  end

  test "cannot access another account's invitations" do
    other_user = User.create!(email_address: "other@example.com", password: "password")
    other_account = Account.create!(name: "Other Account", owner: other_user, bank_holiday_division: "scotland")
    other_invitation = other_account.invitations.create!(invited_by: other_user, email: "someone@example.com")

    delete account_invitation_url(other_invitation)
    assert_response :not_found
  end
end
