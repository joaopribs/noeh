class AddHexCorHoverToCor < ActiveRecord::Migration
  def change
    add_column :cores, :hex_cor_hover, :string
  end
end
