class AddTitleToLeaveEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :leave_entries, :title, :string
  end
end
