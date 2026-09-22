class CreateAdditionalCalendars < ActiveRecord::Migration[8.1]
  DEFAULT_COLOR = "#f59e0b".freeze
  MIGRATED_CALENDAR_NAME = "School Holidays".freeze
  MIGRATED_CALENDAR_DESCRIPTION = "School terms and holiday dates".freeze

  def up
    create_table :additional_calendars do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description
      t.string :color, null: false, default: DEFAULT_COLOR

      t.timestamps
    end

    add_index :additional_calendars, [ :account_id, :name ], unique: true

    create_table :additional_calendar_entries do |t|
      t.references :additional_calendar, null: false, foreign_key: true
      t.string :title, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.text :notes

      t.timestamps
    end

    add_index :additional_calendar_entries, :start_date
    add_index :additional_calendar_entries, :end_date

    backfill_from_school_holidays
  end

  def down
    drop_table :additional_calendar_entries
    drop_table :additional_calendars
  end

  private
    # Deliberately raw SQL rather than the app's models: models track the
    # *current* schema and would make this migration unreplayable later.
    def backfill_from_school_holidays
      return unless table_exists?(:school_holidays)

      source_count = connection.select_value("SELECT COUNT(*) FROM school_holidays").to_i
      return if source_count.zero?

      account_ids = connection.select_values(
        "SELECT DISTINCT account_id FROM school_holidays ORDER BY account_id"
      )

      account_ids.each { |account_id| migrate_account(account_id) }

      copied_count = connection.select_value("SELECT COUNT(*) FROM additional_calendar_entries").to_i

      unless copied_count == source_count
        raise "Aborting migration: copied #{copied_count} entries but school_holidays holds #{source_count}."
      end

      say "Copied #{copied_count} school holiday row(s) into #{account_ids.size} additional calendar(s)."
    end

    def migrate_account(account_id)
      color = dominant_color_for(account_id) || DEFAULT_COLOR
      now = quote(Time.current)

      execute(<<~SQL.squish)
        INSERT INTO additional_calendars (account_id, name, description, color, created_at, updated_at)
        VALUES (
          #{quote(account_id)},
          #{quote(MIGRATED_CALENDAR_NAME)},
          #{quote(MIGRATED_CALENDAR_DESCRIPTION)},
          #{quote(color)},
          #{now},
          #{now}
        )
      SQL

      calendar_id = connection.select_value(<<~SQL.squish)
        SELECT id FROM additional_calendars
        WHERE account_id = #{quote(account_id)} AND name = #{quote(MIGRATED_CALENDAR_NAME)}
      SQL

      execute(<<~SQL.squish)
        INSERT INTO additional_calendar_entries
          (additional_calendar_id, title, start_date, end_date, notes, created_at, updated_at)
        SELECT
          #{quote(calendar_id)}, title, start_date, end_date, notes, created_at, updated_at
        FROM school_holidays
        WHERE account_id = #{quote(account_id)}
        ORDER BY id
      SQL
    end

    def dominant_color_for(account_id)
      connection.select_value(<<~SQL.squish)
        SELECT color FROM school_holidays
        WHERE account_id = #{quote(account_id)} AND color IS NOT NULL AND color != ''
        GROUP BY color
        ORDER BY COUNT(*) DESC, color ASC
        LIMIT 1
      SQL
    end

    def quote(value)
      connection.quote(value)
    end
end
