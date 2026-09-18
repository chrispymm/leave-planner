class RenameFamilyToAccount < ActiveRecord::Migration[8.1]
  # SQLite can only rebuild a table (as required for renaming a column that
  # other tables reference via a foreign key) with FK enforcement truly
  # disabled if it isn't already inside a transaction — PRAGMA foreign_keys
  # is a silent no-op mid-transaction. Rails wraps migrations in an implicit
  # transaction by default, which would otherwise let cascading deletes fire
  # against dependent rows (e.g. leave_entries -> people) while the old
  # "people" table is dropped during the rename. Disabling the automatic
  # transaction lets SQLite's own safety pragma take effect correctly.
  disable_ddl_transaction!

  def change
    rename_table :families, :accounts

    rename_column :people, :family_id, :account_id
    rename_column :school_holidays, :family_id, :account_id
    rename_column :memberships, :family_id, :account_id
  end
end
