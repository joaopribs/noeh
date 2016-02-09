class RenomearParentes < ActiveRecord::Migration
  def change
  	remove_column :parentes, :parentesco, :string
  	add_column :parentes, :relacionamento, :string
    rename_table :parentes, :relacionamentos
  end
end
