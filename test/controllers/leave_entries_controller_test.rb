require "test_helper"

class LeaveEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:chris))
    @person = people(:alice)
    @other_person = people(:bob)
    @leave_entry = leave_entries(:alice_vacation)
  end

  test "should get modal for a date" do
    get modal_leave_entries_url(date: "2026-06-15")
    assert_response :success
    assert_select "turbo-frame#modal_frame"
    assert_select "form[data-turbo-frame='_top']"
    assert_select "input[type='checkbox'][name='leave_entry[person_ids][]']", count: 2
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

  test "should create date range leave for multiple people" do
    assert_difference("LeaveEntry.count", 10) do # Five weekdays for each person
      post leave_entries_url, params: {
        leave_entry: {
          person_ids: [ @person.id, @other_person.id ],
          start_date: "2026-08-10", # Mon
          end_date: "2026-08-14",   # Fri
          half_day: "none"
        }
      }
    end

    assert_redirected_to calendar_url(start_date: Date.current.beginning_of_month.to_s)
    assert_equal 5, @person.leave_entries.where(date: Date.new(2026, 8, 10)..Date.new(2026, 8, 14)).count
    assert_equal 5, @other_person.leave_entries.where(date: Date.new(2026, 8, 10)..Date.new(2026, 8, 14)).count
  end

  test "should update leave entry" do
    patch leave_entry_url(@leave_entry), params: { leave_entry: { half_day: "morning" } }
    assert_redirected_to calendar_url(start_date: Date.current.beginning_of_month.to_s)
    assert_equal "morning", @leave_entry.reload.half_day
  end

  test "should destroy leave entry" do
    assert_difference("LeaveEntry.count", -1) do
      delete leave_entry_url(@leave_entry)
    end

    assert_redirected_to calendar_url(start_date: Date.current.beginning_of_month.to_s)
  end
end
