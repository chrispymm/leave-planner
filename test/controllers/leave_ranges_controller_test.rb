require "test_helper"

class LeaveRangesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = people(:alice)
    @leave_entry = leave_entries(:alice_vacation)
  end

  test "should get index for a person" do
    get person_leave_ranges_url(@person)
    assert_response :success
    assert_select "table[role='grid']"
    assert_select "h2", text: /Leave Ranges/
  end

  test "should get new leave range form" do
    get new_person_leave_range_url(@person)
    assert_response :success
    assert_select "form"
  end

  test "should create leave range across weekdays" do
    assert_difference("LeaveEntry.count", 5) do # Monday to Friday
      post person_leave_ranges_url(@person), params: {
        leave_range: {
          person_id: @person.id,
          start_date: "2026-10-05", # Mon
          end_date: "2026-10-09",   # Fri
          half_day: "none",
          notes: "Autumn break"
        }
      }
    end

    assert_redirected_to person_leave_ranges_url(@person)
  end

  test "should edit and update leave range" do
    # Range ID consists of "first_id-last_id"
    range_id = "#{@leave_entry.id}-#{@leave_entry.id}"
    get edit_leave_range_url(range_id)
    assert_response :success
    assert_select "form[action='#{leave_range_path(range_id)}']"

    patch leave_range_url(range_id), params: {
      leave_range: {
        person_id: @person.id,
        start_date: "2026-06-15",
        end_date: "2026-06-16",
        half_day: "morning",
        notes: "Updated trip"
      }
    }

    assert_redirected_to person_leave_ranges_url(@person)
  end

  test "should create leave range with optional title" do
    assert_difference("LeaveEntry.count", 2) do
      post person_leave_ranges_url(@person), params: {
        leave_range: {
          person_id: @person.id,
          title: "Lake District Trip",
          start_date: "2026-10-05",
          end_date: "2026-10-06",
          half_day: "none"
        }
      }
    end

    assert_redirected_to person_leave_ranges_url(@person)
    entries = LeaveEntry.where(date: Date.new(2026, 10, 5)..Date.new(2026, 10, 6), person: @person)
    assert_equal 2, entries.count
    assert_equal "Lake District Trip", entries.first.title
  end
end
