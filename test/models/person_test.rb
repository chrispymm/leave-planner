require "test_helper"

class PersonTest < ActiveSupport::TestCase
  setup do
    BankHoliday.delete_all
    LeaveEntry.delete_all
    Person.delete_all
  end

  test "calculates leave in days excluding bank holidays by default" do
    person = Person.create!(
      account: accounts(:pymm_account),
      name: "Alice",
      color: "#2563eb",
      allowance_unit: "days",
      allowance_amount: 25.0,
      hours_per_day: 7.5,
      include_bank_holidays: false
    )

    # Add a bank holiday
    bh = BankHoliday.create!(title: "May Bank Holiday", date: Date.new(2026, 5, 4), division: "england-and-wales")

    # Book 3 days: one standard weekday, one bank holiday, one half day
    person.leave_entries.create!(date: Date.new(2026, 5, 1), half_day: "none") # Friday - 1.0 day
    person.leave_entries.create!(date: Date.new(2026, 5, 4), half_day: "none") # Bank holiday Monday - 0.0 day
    person.leave_entries.create!(date: Date.new(2026, 5, 5), half_day: "morning") # Tuesday - 0.5 day

    year_range = Date.new(2026, 1, 1)..Date.new(2026, 12, 31)
    assert_equal 1.5, person.used_allowance(year_range)
    assert_equal 23.5, person.remaining_allowance(year_range)
  end

  test "calculates leave in days including bank holidays when toggled" do
    person = Person.create!(
      account: accounts(:pymm_account),
      name: "Bob",
      color: "#10b981",
      allowance_unit: "days",
      allowance_amount: 30.0,
      hours_per_day: 7.5,
      include_bank_holidays: true
    )

    BankHoliday.create!(title: "May Bank Holiday", date: Date.new(2026, 5, 4), division: "england-and-wales")

    person.leave_entries.create!(date: Date.new(2026, 5, 1), half_day: "none") # 1.0
    person.leave_entries.create!(date: Date.new(2026, 5, 4), half_day: "none") # 1.0 (counted!)

    year_range = Date.new(2026, 1, 1)..Date.new(2026, 12, 31)
    assert_equal 2.0, person.used_allowance(year_range)
    assert_equal 28.0, person.remaining_allowance(year_range)
  end

  test "calculates leave in hours and custom hours per day" do
    person = Person.create!(
      account: accounts(:pymm_account),
      name: "Charlie",
      color: "#f59e0b",
      allowance_unit: "hours",
      allowance_amount: 150.0,
      hours_per_day: 7.5,
      include_bank_holidays: false
    )

    person.leave_entries.create!(date: Date.new(2026, 6, 1), half_day: "none") # 7.5 hours
    person.leave_entries.create!(date: Date.new(2026, 6, 2), half_day: "morning") # 3.75 hours
    person.leave_entries.create!(date: Date.new(2026, 6, 3), half_day: "none", custom_hours: 4.0) # 4.0 hours

    year_range = Date.new(2026, 1, 1)..Date.new(2026, 12, 31)
    assert_equal 15.25, person.used_allowance(year_range)
    assert_equal 134.75, person.remaining_allowance(year_range)
  end

  test "respects custom leave year start day and month" do
    person = Person.create!(
      account: accounts(:pymm_account),
      name: "Dana",
      color: "#8b5cf6",
      allowance_unit: "days",
      allowance_amount: 25.0,
      hours_per_day: 7.5,
      include_bank_holidays: false,
      leave_year_start_month: 4, # April
      leave_year_start_day: 6    # 6th April (Tax year / typical UK corporate reset)
    )

    assert_equal "6th April", person.leave_year_start_day_formatted

    # Date on or after April 6th
    range = person.leave_year_range(Date.new(2026, 9, 15))
    assert_equal Date.new(2026, 4, 6), range.begin
    assert_equal Date.new(2027, 4, 5), range.end

    # Date before April 6th (e.g. April 5th)
    range_pre = person.leave_year_range(Date.new(2026, 4, 5))
    assert_equal Date.new(2025, 4, 6), range_pre.begin
    assert_equal Date.new(2026, 4, 5), range_pre.end

    overlapping_ranges = person.leave_year_ranges_overlapping(Date.new(2027, 1, 1)..Date.new(2027, 12, 31))
    assert_equal [
      Date.new(2026, 4, 6)..Date.new(2027, 4, 5),
      Date.new(2027, 4, 6)..Date.new(2028, 4, 5)
    ], overlapping_ranges
  end

  test "handles mid-year starting leave balance and resets on next leave year" do
    person = Person.create!(
      account: accounts(:pymm_account),
      name: "Edward",
      color: "#0891b2",
      allowance_unit: "days",
      allowance_amount: 25.0,
      hours_per_day: 7.5,
      include_bank_holidays: false,
      leave_year_start_month: 1,
      leave_year_start_day: 1,
      initial_remaining_allowance: 8.5,
      initial_allowance_date: Date.new(2026, 9, 15)
    )

    leave_year_2026 = person.leave_year_range(Date.new(2026, 9, 15)) # 2026-01-01..2026-12-31
    assert person.initial_allowance_active_for?(leave_year_2026)
    assert_equal 8.5, person.starting_allowance(leave_year_2026)

    # Leave before initial_allowance_date should NOT be deducted (already factored in)
    person.leave_entries.create!(date: Date.new(2026, 8, 10), half_day: "none") # 1 day in August

    # Leave on/after initial_allowance_date SHOULD be deducted
    person.leave_entries.create!(date: Date.new(2026, 10, 5), half_day: "none") # 1 day in October
    person.leave_entries.create!(date: Date.new(2026, 10, 6), half_day: "morning") # 0.5 day in October

    assert_equal 1.5, person.used_allowance(leave_year_2026)
    assert_equal 7.0, person.remaining_allowance(leave_year_2026)

    # For the NEXT leave year (2027), initial allowance is NO LONGER relevant
    leave_year_2027 = person.leave_year_range(Date.new(2027, 1, 1)) # 2027-01-01..2027-12-31
    assert_not person.initial_allowance_active_for?(leave_year_2027)
    assert_equal 25.0, person.starting_allowance(leave_year_2027)

    person.leave_entries.create!(date: Date.new(2027, 2, 1), half_day: "none") # 1 day in 2027
    assert_equal 1.0, person.used_allowance(leave_year_2027)
    assert_equal 24.0, person.remaining_allowance(leave_year_2027)
  end
end
