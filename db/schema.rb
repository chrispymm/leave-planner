# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_18_131710) do
  create_table "bank_holidays", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "division", default: "england-and-wales", null: false
    t.text "notes"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "division"], name: "index_bank_holidays_on_date_and_division", unique: true
    t.index ["date"], name: "index_bank_holidays_on_date"
  end

  create_table "families", force: :cascade do |t|
    t.string "bank_holiday_division", default: "england-and-wales", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "owner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_families_on_owner_id"
  end

  create_table "leave_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "custom_hours", precision: 5, scale: 2
    t.date "date", null: false
    t.string "half_day", default: "none", null: false
    t.text "notes"
    t.integer "person_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_leave_entries_on_date"
    t.index ["person_id", "date"], name: "index_leave_entries_on_person_id_and_date", unique: true
    t.index ["person_id"], name: "index_leave_entries_on_person_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "family_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["family_id"], name: "index_memberships_on_family_id"
    t.index ["user_id", "family_id"], name: "index_memberships_on_user_id_and_family_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "people", force: :cascade do |t|
    t.decimal "allowance_amount", precision: 8, scale: 2, default: "25.0", null: false
    t.string "allowance_unit", default: "days", null: false
    t.string "color", default: "#2563eb", null: false
    t.datetime "created_at", null: false
    t.integer "family_id", null: false
    t.decimal "hours_per_day", precision: 5, scale: 2, default: "7.5", null: false
    t.boolean "include_bank_holidays", default: false, null: false
    t.date "initial_allowance_date"
    t.decimal "initial_remaining_allowance", precision: 8, scale: 2
    t.integer "leave_year_start_day", default: 1, null: false
    t.integer "leave_year_start_month", default: 1, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_people_on_family_id"
  end

  create_table "school_holidays", force: :cascade do |t|
    t.string "color", default: "#f59e0b", null: false
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.integer "family_id", null: false
    t.text "notes"
    t.date "start_date", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["end_date"], name: "index_school_holidays_on_end_date"
    t.index ["family_id"], name: "index_school_holidays_on_family_id"
    t.index ["start_date"], name: "index_school_holidays_on_start_date"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "families", "users", column: "owner_id"
  add_foreign_key "leave_entries", "people", on_delete: :cascade
  add_foreign_key "memberships", "families"
  add_foreign_key "memberships", "users"
  add_foreign_key "people", "families"
  add_foreign_key "school_holidays", "families"
  add_foreign_key "sessions", "users"
end
