require "test_helper"

class BankHolidaysControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get bank_holidays_url
    assert_response :success
    assert_select "h2", "UK Bank Holidays"
  end

  test "should sync bank holidays" do
    post sync_bank_holidays_url
    assert_redirected_to bank_holidays_url
    assert_not_nil flash[:notice]
  end
end
