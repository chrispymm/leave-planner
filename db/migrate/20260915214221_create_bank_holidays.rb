class CreateBankHolidays < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_holidays do |t|
      t.string :title, null: false
      t.date :date, null: false
      t.string :division, null: false, default: "england-and-wales"
      t.text :notes

      t.timestamps
    end

    add_index :bank_holidays, [ :date, :division ], unique: true
    add_index :bank_holidays, :date
  end
end
