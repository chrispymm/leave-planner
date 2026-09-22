require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "requires a name and a valid bank_holiday_division" do
    account = Account.new(owner: users(:chris))
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"

    account.name = "Test Account"
    account.bank_holiday_division = "atlantis"
    assert_not account.valid?
    assert_includes account.errors[:bank_holiday_division], "is not included in the list"

    account.bank_holiday_division = "scotland"
    assert account.valid?
  end

  test "has many people and additional calendars, destroyed when account is destroyed" do
    account = accounts(:pymm_account)
    account.people.create!(name: "Zara", color: "#123456", allowance_unit: "days", allowance_amount: 25, hours_per_day: 7.5)

    person_ids = account.people.pluck(:id)
    calendar_ids = account.additional_calendars.pluck(:id)
    entry_ids = account.additional_calendar_entries.pluck(:id)

    assert_not_empty calendar_ids
    assert_not_empty entry_ids

    account.destroy

    assert_empty Person.where(id: person_ids)
    assert_empty AdditionalCalendar.where(id: calendar_ids)
    assert_empty AdditionalCalendarEntry.where(id: entry_ids)
  end
end
