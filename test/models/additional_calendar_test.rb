require "test_helper"

class AdditionalCalendarTest < ActiveSupport::TestCase
  test "requires a name" do
    calendar = accounts(:pymm_account).additional_calendars.new(color: "#123456")

    assert_not calendar.valid?
    assert_includes calendar.errors[:name], "can't be blank"
  end

  test "requires a valid hex colour" do
    calendar = accounts(:pymm_account).additional_calendars.new(name: "Clubs")

    calendar.color = "not-a-colour"
    assert_not calendar.valid?
    assert_includes calendar.errors[:color], "must be a valid hex colour, for example #f59e0b"

    calendar.color = "#abc"
    assert calendar.valid?

    calendar.color = "#a1b2c3"
    assert calendar.valid?
  end

  test "names must be unique per account but may repeat across accounts" do
    duplicate = accounts(:pymm_account).additional_calendars.new(
      name: additional_calendars(:school_holidays).name.downcase,
      color: "#123456"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"

    other_account = Account.create!(
      name: "Other Account",
      owner: User.create!(email_address: "other-calendar@example.com", password: "password"),
      bank_holiday_division: "scotland"
    )
    reused = other_account.additional_calendars.new(name: "School Holidays", color: "#123456")
    assert reused.valid?
  end

  test "destroying a calendar destroys its entries" do
    calendar = additional_calendars(:school_holidays)
    entry_ids = calendar.additional_calendar_entries.pluck(:id)

    assert_not_empty entry_ids

    calendar.destroy

    assert_empty AdditionalCalendarEntry.where(id: entry_ids)
  end

  test "alphabetical orders by name" do
    names = accounts(:pymm_account).additional_calendars.alphabetical.pluck(:name)

    assert_equal names.sort, names
  end
end
