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

ActiveRecord::Schema[8.1].define(version: 2026_09_15_221617) do
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

  create_table "leave_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "custom_hours", precision: 5, scale: 2
    t.date "date", null: false
    t.string "half_day", default: "none", null: false
    t.text "notes"
    t.integer "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_leave_entries_on_date"
    t.index ["person_id", "date"], name: "index_leave_entries_on_person_id_and_date", unique: true
    t.index ["person_id"], name: "index_leave_entries_on_person_id"
  end

  create_table "people", force: :cascade do |t|
    t.decimal "allowance_amount", precision: 8, scale: 2, default: "25.0", null: false
    t.string "allowance_unit", default: "days", null: false
    t.string "color", default: "#2563eb", null: false
    t.datetime "created_at", null: false
    t.decimal "hours_per_day", precision: 5, scale: 2, default: "7.5", null: false
    t.boolean "include_bank_holidays", default: false, null: false
    t.date "initial_allowance_date"
    t.decimal "initial_remaining_allowance", precision: 8, scale: 2
    t.integer "leave_year_start_day", default: 1, null: false
    t.integer "leave_year_start_month", default: 1, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "school_holidays", force: :cascade do |t|
    t.string "color", default: "#f59e0b", null: false
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.text "notes"
    t.date "start_date", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["end_date"], name: "index_school_holidays_on_end_date"
    t.index ["start_date"], name: "index_school_holidays_on_start_date"
  end

  add_foreign_key "leave_entries", "people", on_delete: :cascade
end
