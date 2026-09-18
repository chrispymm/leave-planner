require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "a user cannot be a member of the same account twice" do
    membership = Membership.new(user: users(:chris), account: accounts(:pymm_account))
    assert_not membership.valid?
    assert_includes membership.errors[:user_id], "has already been taken"
  end

  test "allows the same user to join a different account" do
    other_account = Account.create!(name: "Other Account", owner: users(:jess), bank_holiday_division: "scotland")
    membership = Membership.new(user: users(:chris), account: other_account)
    assert membership.valid?
  end
end
