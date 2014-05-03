class RenomearCamposDePessoas2 < ActiveRecord::Migration
  def change
    rename_column :pessoas, :ehHomem, :eh_homem
  end
end
