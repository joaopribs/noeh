class RenomearCamposDeRelacoesPessoaGrupo < ActiveRecord::Migration
  def change
    remove_column :relacoes_pessoa_grupo, :pastoral_id
    add_column :relacoes_pessoa_grupo, :grupo_id, :integer
  end
end
