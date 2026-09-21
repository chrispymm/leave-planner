require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  test "owner can remove a non-owner member" do
    sign_in_as(users(:chris))
    membership = memberships(:jess_membership)

    assert_difference("Membership.count", -1) do
      delete account_membership_url(membership)
    end

    assert_redirected_to edit_account_path
  end

  test "non-owner cannot remove any member" do
    sign_in_as(users(:jess))
    membership = memberships(:jess_membership)

    assert_no_difference("Membership.count") do
      delete account_membership_url(membership)
    end

    assert_redirected_to edit_account_path
  end

  test "owner cannot remove themselves" do
    sign_in_as(users(:chris))
    membership = memberships(:chris_membership)

    assert_no_difference("Membership.count") do
      delete account_membership_url(membership)
    end

    assert_redirected_to edit_account_path
  end
end
