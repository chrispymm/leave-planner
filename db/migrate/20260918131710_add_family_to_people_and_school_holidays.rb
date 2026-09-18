class AddFamilyToPeopleAndSchoolHolidays < ActiveRecord::Migration[8.1]
  def up
    add_reference :people, :family, foreign_key: true
    add_reference :school_holidays, :family, foreign_key: true

    backfill_default_family!

    change_column_null :people, :family_id, false
    change_column_null :school_holidays, :family_id, false
  end

  def down
    remove_reference :people, :family, foreign_key: true
    remove_reference :school_holidays, :family, foreign_key: true
  end

  private

  # Any pre-existing People/SchoolHolidays predate the family/user model.
  # Assign them all to a single default family (and default owning user), so
  # existing data keeps working after this migration.
  def backfill_default_family!
    Person.reset_column_information
    SchoolHoliday.reset_column_information

    return if Person.none? && SchoolHoliday.none?

    user = User.first || User.create!(email_address: "owner@example.com", password: "password")
    family = Family.create!(name: "Family", owner: user, bank_holiday_division: "england-and-wales")
    Membership.find_or_create_by!(user: user, family: family)

    Person.where(family_id: nil).update_all(family_id: family.id)
    SchoolHoliday.where(family_id: nil).update_all(family_id: family.id)
  end
end
