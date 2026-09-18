require "test_helper"

class FamilyTest < ActiveSupport::TestCase
  test "requires a name and a valid bank_holiday_division" do
    family = Family.new(owner: users(:chris))
    assert_not family.valid?
    assert_includes family.errors[:name], "can't be blank"

    family.name = "Test Family"
    family.bank_holiday_division = "atlantis"
    assert_not family.valid?
    assert_includes family.errors[:bank_holiday_division], "is not included in the list"

    family.bank_holiday_division = "scotland"
    assert family.valid?
  end

  test "has many people and school holidays, destroyed when family is destroyed" do
    family = families(:pymm_family)
    family.people.create!(name: "Zara", color: "#123456", allowance_unit: "days", allowance_amount: 25, hours_per_day: 7.5)
    family.school_holidays.create!(title: "Summer", start_date: Date.new(2026, 7, 1), end_date: Date.new(2026, 8, 1))

    person_ids = family.people.pluck(:id)
    holiday_ids = family.school_holidays.pluck(:id)

    family.destroy

    assert_empty Person.where(id: person_ids)
    assert_empty SchoolHoliday.where(id: holiday_ids)
  end
end
