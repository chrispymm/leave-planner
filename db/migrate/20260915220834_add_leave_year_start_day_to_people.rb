class AddLeaveYearStartDayToPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :leave_year_start_day, :integer, null: false, default: 1
  end
end
