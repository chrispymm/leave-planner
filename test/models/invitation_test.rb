require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "generates a unique token and default expiry on create" do
    invitation = Invitation.create!(account: accounts(:pymm_account), invited_by: users(:chris), email: "new-person@example.com")

    assert_not_nil invitation.token
    assert invitation.expires_at > 47.hours.from_now
    assert invitation.expires_at < 49.hours.from_now
  end

  test "requires a valid email format" do
    invitation = Invitation.new(account: accounts(:pymm_account), invited_by: users(:chris), email: "not-an-email")
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "is invalid"
  end

  test "rejects inviting an email that already belongs to a user" do
    invitation = Invitation.new(account: accounts(:pymm_account), invited_by: users(:chris), email: users(:jess).email_address)
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "already has an account"
  end

  test "rejects a duplicate pending invitation for the same email in the same account" do
    Invitation.create!(account: accounts(:pymm_account), invited_by: users(:chris), email: "new-person@example.com")
    duplicate = Invitation.new(account: accounts(:pymm_account), invited_by: users(:chris), email: "new-person@example.com")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "already has a pending invitation"
  end

  test "#expired? and #pending? reflect expiry" do
    invitation = Invitation.create!(account: accounts(:pymm_account), invited_by: users(:chris), email: "new-person@example.com")
    assert invitation.pending?
    assert_not invitation.expired?

    invitation.update_column(:expires_at, 1.hour.ago)
    assert invitation.expired?
    assert_not invitation.pending?
  end

  test "#accepted? reflects accepted_at" do
    invitation = Invitation.create!(account: accounts(:pymm_account), invited_by: users(:chris), email: "new-person@example.com")
    assert_not invitation.accepted?

    invitation.update_column(:accepted_at, Time.current)
    assert invitation.accepted?
    assert_not invitation.pending?
  end

  test "pending scope excludes accepted and expired invitations" do
    pending = Invitation.create!(account: accounts(:pymm_account), invited_by: users(:chris), email: "pending@example.com")
    accepted = Invitation.create!(account: accounts(:pymm_account), invited_by: users(:chris), email: "accepted@example.com")
    accepted.update_column(:accepted_at, Time.current)
    expired = Invitation.create!(account: accounts(:pymm_account), invited_by: users(:chris), email: "expired@example.com")
    expired.update_column(:expires_at, 1.hour.ago)

    assert_equal [ pending ], Invitation.pending.to_a
  end
end
