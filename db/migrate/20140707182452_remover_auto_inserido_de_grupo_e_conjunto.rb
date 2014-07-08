class RemoverAutoInseridoDeGrupoEConjunto < ActiveRecord::Migration
  def change
    remove_column :relacoes_pessoa_grupo, :auto_inserido, :boolean
    remove_column :relacoes_pessoa_conjunto, :auto_inserido, :boolean
  end
end
