class CreateFamilies < ActiveRecord::Migration[8.1]
  def change
    create_table :families do |t|
      t.string :name
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :bank_holiday_division, null: false, default: "england-and-wales"

      t.timestamps
    end
  end
end
