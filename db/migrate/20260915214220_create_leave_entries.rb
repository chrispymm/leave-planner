class CreateLeaveEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_entries do |t|
      t.references :person, null: false, foreign_key: { on_delete: :cascade }
      t.date :date, null: false
      t.string :half_day, null: false, default: "none"
      t.decimal :custom_hours, precision: 5, scale: 2
      t.text :notes

      t.timestamps
    end

    add_index :leave_entries, [ :person_id, :date ], unique: true
    add_index :leave_entries, :date
  end
end
