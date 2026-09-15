require "test_helper"

class SchoolHolidayTest < ActiveSupport::TestCase
  test "validates end date is after or equal to start date" do
    valid = SchoolHoliday.new(title: "Summer", start_date: Date.new(2026, 7, 20), end_date: Date.new(2026, 9, 1))
    assert valid.valid?

    invalid = SchoolHoliday.new(title: "Invalid", start_date: Date.new(2026, 7, 20), end_date: Date.new(2026, 7, 19))
    assert_not invalid.valid?
    assert_includes invalid.errors[:end_date], "must be on or after the start date"
  end

  test "map_by_date returns correct holiday mapping" do
    SchoolHoliday.delete_all
    sh = SchoolHoliday.create!(title: "Half Term", start_date: Date.new(2026, 10, 26), end_date: Date.new(2026, 10, 30))
    mapping = SchoolHoliday.map_by_date(Date.new(2026, 10, 1), Date.new(2026, 10, 31))

    assert_equal [ sh ], mapping[Date.new(2026, 10, 26)]
    assert_equal [ sh ], mapping[Date.new(2026, 10, 30)]
    assert_empty mapping[Date.new(2026, 10, 25)]
  end
end
