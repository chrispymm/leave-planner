require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  test "should get show with default 12 months without top header" do
    get root_url
    assert_response :success
    assert_select "header.site-nav", count: 0
    assert_select "turbo-frame#calendar_frame"
    assert_select ".month-card", count: 12
  end

  test "should navigate to a specific start_date" do
    get calendar_url(start_date: "2027-01-01")
    assert_response :success
    assert_select ".calendar-controls", /January 2027/
  end

  test "should show edit person settings cog link and holiday calendar links in sidebar" do
    get root_url
    assert_response :success
    people.each do |person|
      assert_select "a[href='#{edit_person_path(person)}'][data-turbo-frame='_top']", text: "⚙️"
      assert_select "a[href='#{person_leave_ranges_path(person)}'][data-turbo-frame='_top']", text: person.name
    end

    assert_select "a[href='#{school_holidays_path}'][data-turbo-frame='_top']"
    assert_select "a[href='#{bank_holidays_path}'][data-turbo-frame='_top']"
  end
end
