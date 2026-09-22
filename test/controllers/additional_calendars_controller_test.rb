require "test_helper"

class AdditionalCalendarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:chris))
    @additional_calendar = additional_calendars(:school_holidays)
  end

  test "requires authentication" do
    sign_out

    get additional_calendars_url
    assert_redirected_to new_session_path
  end

  test "should list the account's calendars with entry counts" do
    get additional_calendars_url

    assert_response :success
    assert_select "td", text: @additional_calendar.name
    assert_select "td", text: "2 entries"
  end

  test "should show a calendar and its entries" do
    get additional_calendar_url(@additional_calendar)

    assert_response :success
    assert_select "h2", text: @additional_calendar.name
    assert_select "td strong", text: "Summer Holidays"
  end

  test "should get new and create a calendar" do
    get new_additional_calendar_url
    assert_response :success

    assert_difference("AdditionalCalendar.count", 1) do
      post additional_calendars_url, params: {
        additional_calendar: { name: "Clubs", description: "After school clubs", color: "#112233" }
      }
    end

    calendar = AdditionalCalendar.find_by(name: "Clubs")
    assert_redirected_to additional_calendar_url(calendar)
    assert_equal accounts(:pymm_account), calendar.account
    assert_equal "#112233", calendar.color
  end

  test "rejects an invalid calendar" do
    assert_no_difference("AdditionalCalendar.count") do
      post additional_calendars_url, params: {
        additional_calendar: { name: "", color: "nope" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit and update a calendar" do
    get edit_additional_calendar_url(@additional_calendar)
    assert_response :success

    patch additional_calendar_url(@additional_calendar), params: {
      additional_calendar: { name: "Term Dates", color: "#654321" }
    }

    assert_redirected_to additional_calendar_url(@additional_calendar)
    @additional_calendar.reload
    assert_equal "Term Dates", @additional_calendar.name
    assert_equal "#654321", @additional_calendar.color
  end

  test "destroying a calendar removes its entries too" do
    entry_ids = @additional_calendar.additional_calendar_entries.pluck(:id)

    assert_difference("AdditionalCalendar.count", -1) do
      delete additional_calendar_url(@additional_calendar)
    end

    assert_redirected_to additional_calendars_url
    assert_empty AdditionalCalendarEntry.where(id: entry_ids)
  end

  test "cannot view, edit, update or destroy another account's calendar" do
    other_calendar = other_account.additional_calendars.create!(name: "Secret", color: "#000000")

    get additional_calendar_url(other_calendar)
    assert_response :not_found

    get edit_additional_calendar_url(other_calendar)
    assert_response :not_found

    patch additional_calendar_url(other_calendar), params: {
      additional_calendar: { name: "Hacked" }
    }
    assert_response :not_found

    delete additional_calendar_url(other_calendar)
    assert_response :not_found

    assert_equal "Secret", other_calendar.reload.name
  end

  private
    def other_account
      @other_account ||= Account.create!(
        name: "Other Account",
        owner: User.create!(email_address: "other-cal@example.com", password: "password"),
        bank_holiday_division: "scotland"
      )
    end
end
