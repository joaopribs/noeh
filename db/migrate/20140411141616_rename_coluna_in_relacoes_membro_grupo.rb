class RenameColunaInRelacoesMembroGrupo < ActiveRecord::Migration
  def change
    rename_column :relacoes_membro_grupo, :pessoa_id, :membro_id
  end
end
