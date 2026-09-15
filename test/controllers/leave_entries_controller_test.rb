require "test_helper"

class LeaveEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = people(:alice)
    @leave_entry = leave_entries(:alice_vacation)
  end

  test "should get modal for a date" do
    get modal_leave_entries_url(date: "2026-06-15", person_id: @person.id)
    assert_response :success
    assert_select "turbo-frame#modal_frame"
  end

  test "should toggle leave entry on and off" do
    # Date without entry: toggles ON
    target_date = "2026-07-10"
    assert_difference("LeaveEntry.count", 1) do
      post toggle_leave_entries_url, params: { person_id: @person.id, date: target_date }
    end

    # Toggles OFF
    assert_difference("LeaveEntry.count", -1) do
      post toggle_leave_entries_url, params: { person_id: @person.id, date: target_date }
    end
  end

  test "should create date range leave" do
    assert_difference("LeaveEntry.count", 5) do # Mon-Fri
      post leave_entries_url, params: {
        leave_entry: {
          person_id: @person.id,
          start_date: "2026-08-10", # Mon
          end_date: "2026-08-14",   # Fri
          half_day: "none"
        }
      }
    end

    assert_redirected_to calendar_url(start_date: Date.current.beginning_of_month.to_s, person_id: @person.id)
  end

  test "should update leave entry" do
    patch leave_entry_url(@leave_entry), params: { leave_entry: { half_day: "morning" } }
    assert_redirected_to calendar_url(start_date: Date.current.beginning_of_month.to_s, person_id: @person.id)
    assert_equal "morning", @leave_entry.reload.half_day
  end

  test "should destroy leave entry" do
    assert_difference("LeaveEntry.count", -1) do
      delete leave_entry_url(@leave_entry)
    end

    assert_redirected_to calendar_url(start_date: Date.current.beginning_of_month.to_s, person_id: @person.id)
  end
end
