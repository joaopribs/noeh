class AjeitarProblemas < ActiveRecord::Migration
  def change
  	remove_column :problemas, :problema, :integer
  	add_column :problemas, :problema, :string
  end
end
