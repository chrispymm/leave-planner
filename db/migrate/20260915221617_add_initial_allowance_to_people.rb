class AddInitialAllowanceToPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :initial_remaining_allowance, :decimal, precision: 8, scale: 2
    add_column :people, :initial_allowance_date, :date
  end
end
