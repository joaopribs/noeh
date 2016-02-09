class RemoverParentesco < ActiveRecord::Migration
  def change
  	drop_table :paretesco
  end
end
