class AddCalendarLayoutToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :calendar_layout, :string, default: "grid", null: false
  end
end
