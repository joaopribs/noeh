class RenomearProblemas < ActiveRecord::Migration
  def change
  	remove_column :problemas, :problema, :string
  	add_column :problemas, :log, :string
    rename_table :problemas, :logs_persistentes
  end
end
