class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :name, null: false
      t.string :color, null: false, default: "#2563eb"
      t.string :allowance_unit, null: false, default: "days"
      t.decimal :allowance_amount, precision: 8, scale: 2, null: false, default: 25.0
      t.decimal :hours_per_day, precision: 5, scale: 2, null: false, default: 7.5
      t.boolean :include_bank_holidays, null: false, default: false
      t.integer :leave_year_start_month, null: false, default: 1

      t.timestamps
    end
  end
end
