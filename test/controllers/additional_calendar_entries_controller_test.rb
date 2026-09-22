require "test_helper"

class AdditionalCalendarEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:chris))
    @additional_calendar = additional_calendars(:school_holidays)
    @entry = additional_calendar_entries(:summer)
  end

  test "requires authentication" do
    sign_out

    get new_additional_calendar_additional_calendar_entry_url(@additional_calendar)
    assert_redirected_to new_session_path
  end

  test "should get new and create an entry on the calendar" do
    get new_additional_calendar_additional_calendar_entry_url(@additional_calendar)
    assert_response :success

    assert_difference("AdditionalCalendarEntry.count", 1) do
      post additional_calendar_additional_calendar_entries_url(@additional_calendar), params: {
        additional_calendar_entry: {
          title: "Inset Day",
          start_date: "2027-03-01",
          end_date: "2027-03-01",
          notes: "Staff training"
        }
      }
    end

    assert_redirected_to additional_calendar_url(@additional_calendar)
    entry = AdditionalCalendarEntry.find_by(title: "Inset Day")
    assert_equal @additional_calendar, entry.additional_calendar
    assert_equal "Staff training", entry.notes
  end

  test "rejects an entry ending before it starts" do
    assert_no_difference("AdditionalCalendarEntry.count") do
      post additional_calendar_additional_calendar_entries_url(@additional_calendar), params: {
        additional_calendar_entry: {
          title: "Backwards",
          start_date: "2027-03-10",
          end_date: "2027-03-01"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit and update an entry" do
    get edit_additional_calendar_entry_url(@entry)
    assert_response :success

    patch additional_calendar_entry_url(@entry), params: {
      additional_calendar_entry: { title: "Summer Holidays Updated" }
    }

    assert_redirected_to additional_calendar_url(@additional_calendar)
    assert_equal "Summer Holidays Updated", @entry.reload.title
  end

  test "should destroy an entry" do
    assert_difference("AdditionalCalendarEntry.count", -1) do
      delete additional_calendar_entry_url(@entry)
    end

    assert_redirected_to additional_calendar_url(@additional_calendar)
  end

  test "cannot add to, edit, update or destroy entries on another account's calendar" do
    other_calendar = other_account.additional_calendars.create!(name: "Secret", color: "#000000")
    other_entry = other_calendar.additional_calendar_entries.create!(
      title: "Secret Entry",
      start_date: Date.new(2027, 1, 1),
      end_date: Date.new(2027, 1, 7)
    )

    get new_additional_calendar_additional_calendar_entry_url(other_calendar)
    assert_response :not_found

    assert_no_difference("AdditionalCalendarEntry.count") do
      post additional_calendar_additional_calendar_entries_url(other_calendar), params: {
        additional_calendar_entry: { title: "Injected", start_date: "2027-02-01", end_date: "2027-02-02" }
      }
    end
    assert_response :not_found

    get edit_additional_calendar_entry_url(other_entry)
    assert_response :not_found

    patch additional_calendar_entry_url(other_entry), params: {
      additional_calendar_entry: { title: "Hacked" }
    }
    assert_response :not_found

    delete additional_calendar_entry_url(other_entry)
    assert_response :not_found

    assert_equal "Secret Entry", other_entry.reload.title
  end

  private
    def other_account
      @other_account ||= Account.create!(
        name: "Other Account",
        owner: User.create!(email_address: "other-entry@example.com", password: "password"),
        bank_holiday_division: "scotland"
      )
    end
end
