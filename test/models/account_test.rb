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

  test "has many people and school holidays, destroyed when account is destroyed" do
    account = accounts(:pymm_account)
    account.people.create!(name: "Zara", color: "#123456", allowance_unit: "days", allowance_amount: 25, hours_per_day: 7.5)
    account.school_holidays.create!(title: "Summer", start_date: Date.new(2026, 7, 1), end_date: Date.new(2026, 8, 1))

    person_ids = account.people.pluck(:id)
    holiday_ids = account.school_holidays.pluck(:id)

    account.destroy

    assert_empty Person.where(id: person_ids)
    assert_empty SchoolHoliday.where(id: holiday_ids)
  end
end
