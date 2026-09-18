require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "a user cannot be a member of the same family twice" do
    membership = Membership.new(user: users(:chris), family: families(:pymm_family))
    assert_not membership.valid?
    assert_includes membership.errors[:user_id], "has already been taken"
  end

  test "allows the same user to join a different family" do
    other_family = Family.create!(name: "Other Family", owner: users(:jess), bank_holiday_division: "scotland")
    membership = Membership.new(user: users(:chris), family: other_family)
    assert membership.valid?
  end
end
