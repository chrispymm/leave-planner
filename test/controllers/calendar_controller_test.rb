require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  test "should get show with default 12 months" do
    get root_url
    assert_response :success
    assert_select "turbo-frame#calendar_frame"
    assert_select ".month-card", count: 12
  end

  test "should navigate to a specific start_date" do
    get calendar_url(start_date: "2027-01-01")
    assert_response :success
    assert_select ".calendar-controls", /January 2027/
  end
end
