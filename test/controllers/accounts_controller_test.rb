require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:chris))
  end

  test "should get edit" do
    get edit_account_url
    assert_response :success
    assert_select "select#account_bank_holiday_division"
  end

  test "lists members with an edit link only for the current user, and a remove button for the owner" do
    get edit_account_url
    assert_response :success

    assert_select "body", /#{users(:chris).email_address}/
    assert_select "body", /#{users(:jess).email_address}/
    assert_select "a[href=?]", edit_profile_path, text: "Edit"
    assert_select "form[action=?]", account_membership_path(memberships(:jess_membership))
  end

  test "does not show a remove button to a non-owner" do
    sign_in_as(users(:jess))
    get edit_account_url
    assert_response :success
    assert_select "form[action=?]", account_membership_path(memberships(:chris_membership)), false
  end

  test "should update account name and bank holiday division" do
    patch account_url, params: { account: { name: "The Pymm Household", bank_holiday_division: "scotland" } }
    assert_redirected_to edit_account_path
    accounts(:pymm_account).reload
    assert_equal "The Pymm Household", accounts(:pymm_account).name
    assert_equal "scotland", accounts(:pymm_account).bank_holiday_division
  end

  test "rejects an invalid bank_holiday_division" do
    patch account_url, params: { account: { bank_holiday_division: "narnia" } }
    assert_response :unprocessable_entity
  end
end
