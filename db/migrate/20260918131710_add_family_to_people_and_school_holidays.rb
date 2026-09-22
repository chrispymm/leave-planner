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
  #
  # Uses raw SQL rather than the application's model classes: those track the
  # *current* schema (and `Family` has since been renamed to `Account`, while
  # `SchoolHoliday` has been removed entirely), so referencing them here would
  # make this migration unreplayable from scratch.
  def backfill_default_family!
    orphan_people = select_value("SELECT COUNT(*) FROM people WHERE family_id IS NULL").to_i
    orphan_holidays = select_value("SELECT COUNT(*) FROM school_holidays WHERE family_id IS NULL").to_i
    return if orphan_people.zero? && orphan_holidays.zero?

    now = Time.current

    user_id = select_value("SELECT id FROM users ORDER BY id LIMIT 1")
    if user_id.blank?
      execute(sanitize(<<~SQL.squish, BCrypt::Password.create("password"), now, now))
        INSERT INTO users (email_address, password_digest, created_at, updated_at)
        VALUES ('owner@example.com', ?, ?, ?)
      SQL
      user_id = select_value("SELECT id FROM users ORDER BY id DESC LIMIT 1")
    end

    execute(sanitize(<<~SQL.squish, user_id, now, now))
      INSERT INTO families (name, owner_id, bank_holiday_division, created_at, updated_at)
      VALUES ('Family', ?, 'england-and-wales', ?, ?)
    SQL
    family_id = select_value("SELECT id FROM families ORDER BY id DESC LIMIT 1")

    membership = select_value(sanitize("SELECT COUNT(*) FROM memberships WHERE user_id = ? AND family_id = ?", user_id, family_id)).to_i
    if membership.zero?
      execute(sanitize(<<~SQL.squish, user_id, family_id, now, now))
        INSERT INTO memberships (user_id, family_id, created_at, updated_at)
        VALUES (?, ?, ?, ?)
      SQL
    end

    execute(sanitize("UPDATE people SET family_id = ? WHERE family_id IS NULL", family_id))
    execute(sanitize("UPDATE school_holidays SET family_id = ? WHERE family_id IS NULL", family_id))
  end

  def select_value(sql)
    connection.select_value(sql)
  end

  def sanitize(sql, *args)
    ActiveRecord::Base.sanitize_sql_array([ sql, *args ])
  end
end
