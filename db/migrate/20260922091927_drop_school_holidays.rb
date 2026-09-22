class DropSchoolHolidays < ActiveRecord::Migration[8.1]
  # Safe with respect to the earlier Account-rename incident: school_holidays
  # is a leaf table (a child of accounts with no FK-dependent children), so
  # dropping it cannot cascade into any other data. Its rows were copied into
  # additional_calendar_entries by CreateAdditionalCalendars and verified
  # before this ran.
  def up
    drop_table :school_holidays
  end

  # Restores only the calendars this migration pair created ("School Holidays"),
  # not every additional calendar. Without that filter a rollback would flatten
  # unrelated user-created calendars (e.g. "Swimming Lessons") into school
  # holiday rows and lose the calendar boundaries entirely.
  def down
    create_table :school_holidays do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :color, null: false, default: "#f59e0b"
      t.text :notes

      t.timestamps
    end

    add_index :school_holidays, :start_date
    add_index :school_holidays, :end_date

    execute(<<~SQL.squish)
      INSERT INTO school_holidays
        (account_id, title, start_date, end_date, color, notes, created_at, updated_at)
      SELECT
        c.account_id, e.title, e.start_date, e.end_date, c.color, e.notes, e.created_at, e.updated_at
      FROM additional_calendar_entries e
      INNER JOIN additional_calendars c ON c.id = e.additional_calendar_id
      WHERE c.name = 'School Holidays'
      ORDER BY e.id
    SQL
  end
end
