class RenomearCamposDePessoas3 < ActiveRecord::Migration
  def change
    rename_column :pessoas, :nome_simplificado, :nome_usual
  end
end
