require "test_helper"

class AdditionalCalendarEntryTest < ActiveSupport::TestCase
  setup do
    @calendar = additional_calendars(:school_holidays)
  end

  test "requires a title and both dates" do
    entry = @calendar.additional_calendar_entries.new

    assert_not entry.valid?
    assert_includes entry.errors[:title], "can't be blank"
    assert_includes entry.errors[:start_date], "can't be blank"
    assert_includes entry.errors[:end_date], "can't be blank"
  end

  test "end date must be on or after the start date" do
    entry = @calendar.additional_calendar_entries.new(
      title: "Backwards",
      start_date: Date.new(2026, 5, 10),
      end_date: Date.new(2026, 5, 9)
    )

    assert_not entry.valid?
    assert_includes entry.errors[:end_date], "must be on or after the start date"

    entry.end_date = entry.start_date
    assert entry.valid?
  end

  test "overlapping finds entries intersecting the window" do
    titles = AdditionalCalendarEntry.overlapping(Date.new(2026, 10, 27), Date.new(2026, 10, 28)).pluck(:title)

    assert_includes titles, "Autumn Half Term"
    assert_includes titles, "Autumn Swimming Block"
    assert_not_includes titles, "Summer Holidays"
  end

  test "map_by_date expands ranges and clips to the window" do
    map = AdditionalCalendarEntry.map_by_date(Date.new(2026, 10, 27), Date.new(2026, 10, 29))

    assert_equal [ Date.new(2026, 10, 27), Date.new(2026, 10, 28), Date.new(2026, 10, 29) ].sort,
      map.keys.sort
    assert_nil map.keys.find { |date| date < Date.new(2026, 10, 27) }
  end

  test "map_by_date returns entries from every overlapping calendar for a shared day" do
    map = AdditionalCalendarEntry.map_by_date(Date.new(2026, 10, 27), Date.new(2026, 10, 27))
    colors = map[Date.new(2026, 10, 27)].map(&:calendar_color)

    assert_equal 2, map[Date.new(2026, 10, 27)].size
    assert_includes colors, additional_calendars(:school_holidays).color
    assert_includes colors, additional_calendars(:swimming).color
  end

  test "duration_in_days counts inclusively" do
    entry = @calendar.additional_calendar_entries.new(
      start_date: Date.new(2026, 5, 10),
      end_date: Date.new(2026, 5, 10)
    )
    assert_equal 1, entry.duration_in_days

    entry.end_date = Date.new(2026, 5, 14)
    assert_equal 5, entry.duration_in_days
  end
end
