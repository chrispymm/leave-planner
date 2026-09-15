class CreateSchoolHolidays < ActiveRecord::Migration[8.1]
  def change
    create_table :school_holidays do |t|
      t.string :title, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :color, null: false, default: "#f59e0b"
      t.text :notes

      t.timestamps
    end

    add_index :school_holidays, :start_date
    add_index :school_holidays, :end_date
  end
end
