require "test_helper"

class LeaveEntryTest < ActiveSupport::TestCase
  setup do
    @person = people(:alice)
    @person.leave_entries.destroy_all
  end

  test "first_in_range? and last_in_range? for a single-day entry" do
    entry = LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 6), half_day: "none") # Mon

    assert entry.first_in_range?
    assert entry.last_in_range?
  end

  test "first_in_range? and last_in_range? across contiguous weekdays" do
    mon = LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 6), half_day: "none", notes: "Holiday")
    tue = LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 7), half_day: "none", notes: "Holiday")
    wed = LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 8), half_day: "none", notes: "Holiday")

    assert mon.first_in_range?
    assert_not mon.last_in_range?

    assert_not tue.first_in_range?
    assert_not tue.last_in_range?

    assert_not wed.first_in_range?
    assert wed.last_in_range?
  end

  test "first_in_range? and last_in_range? bridge a Friday/Monday weekend" do
    fri = LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 10), half_day: "none") # Fri
    mon = LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 13), half_day: "none") # Mon

    assert fri.first_in_range?
    assert_not fri.last_in_range?

    assert_not mon.first_in_range?
    assert mon.last_in_range?
  end

  test "first_in_range? and last_in_range? are true when attributes differ from neighbour" do
    LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 6), half_day: "none", notes: "Trip A") # Mon
    different_notes = LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 7), half_day: "none", notes: "Trip B") # Tue

    assert different_notes.first_in_range?
    assert different_notes.last_in_range?
  end

  test "first_in_range? and last_in_range? are true when adjacent day has no entry" do
    LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 6), half_day: "none") # Mon
    # Tue has no entry, so Wed is not contiguous with Mon
    wed = LeaveEntry.create!(person: @person, date: Date.new(2026, 7, 8), half_day: "none")

    assert wed.first_in_range?
    assert wed.last_in_range?
  end
end
