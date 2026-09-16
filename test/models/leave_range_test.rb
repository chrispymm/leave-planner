require "test_helper"

class LeaveRangeTest < ActiveSupport::TestCase
  setup do
    @person = people(:alice)
    @person.leave_entries.destroy_all
  end

  test "groups contiguous weekdays into a single leave range" do
    # Create Mon-Wed
    LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 6), half_day: "none", notes: "Holiday")
    LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 7), half_day: "none", notes: "Holiday")
    LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 8), half_day: "none", notes: "Holiday")

    ranges = LeaveRange.for_person(@person)
    assert_equal 1, ranges.size
    assert_equal Date.new(2026, 7, 6), ranges.first.start_date
    assert_equal Date.new(2026, 7, 8), ranges.first.end_date
    assert_equal 3, ranges.first.duration_days
    assert_equal 3, ranges.first.working_days_count
    assert_equal "3 days", ranges.first.duration_display
  end

  test "groups across weekend into a single range if Friday and Monday" do
    LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 10), half_day: "none") # Fri
    LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 13), half_day: "none") # Mon

    ranges = LeaveRange.for_person(@person)
    assert_equal 1, ranges.size
    assert_equal Date.new(2026, 7, 10), ranges.first.start_date
    assert_equal Date.new(2026, 7, 13), ranges.first.end_date
    assert_equal 4, ranges.first.duration_days
    assert_equal 2, ranges.first.working_days_count
  end

  test "display_title returns title if present, otherwise formatted dates" do
    LeaveEntry.create!(person: @person, title: "Summer Road Trip", date: Date.new(2026, 7, 6), half_day: "none")
    ranges = LeaveRange.for_person(@person)
    assert_equal 1, ranges.size
    assert_equal "Summer Road Trip", ranges.first.display_title

    LeaveEntry.where(person: @person).delete_all
    LeaveEntry.create!(person: @person, title: nil, date: Date.new(2026, 7, 6), half_day: "none")
    LeaveEntry.create!(person: @person, title: nil, date: Date.new(2026, 7, 7), half_day: "none")
    ranges = LeaveRange.for_person(@person)
    assert_equal 1, ranges.size
    assert_equal "Mon, 6 Jul 2026 – Tue, 7 Jul 2026", ranges.first.display_title
  end
end
