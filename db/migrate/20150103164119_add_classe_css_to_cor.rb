class AddClasseCssToCor < ActiveRecord::Migration
  def change
    add_column :cores, :classe_css, :string
  end
end
