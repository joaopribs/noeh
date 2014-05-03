class RenameColunaEmRelacoesPessoaGrupo < ActiveRecord::Migration
  def change
    rename_column :relacoes_pessoa_grupo, :membro_id, :pessoa_id
  end
end
