require "test_helper"

class FamiliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:chris))
  end

  test "should get edit" do
    get edit_family_url
    assert_response :success
    assert_select "select#family_bank_holiday_division"
  end

  test "should update family name and bank holiday division" do
    patch family_url, params: { family: { name: "The Pymm Household", bank_holiday_division: "scotland" } }
    assert_redirected_to edit_family_path
    families(:pymm_family).reload
    assert_equal "The Pymm Household", families(:pymm_family).name
    assert_equal "scotland", families(:pymm_family).bank_holiday_division
  end

  test "rejects an invalid bank_holiday_division" do
    patch family_url, params: { family: { bank_holiday_division: "narnia" } }
    assert_response :unprocessable_entity
  end
end
