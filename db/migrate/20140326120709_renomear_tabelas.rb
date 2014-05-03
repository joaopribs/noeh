class RenomearTabelas < ActiveRecord::Migration
  def change
    rename_table :pastorais, :grupos
    rename_table :relacoes_pessoa_pastoral, :relacoes_pessoa_grupo
  end
end
