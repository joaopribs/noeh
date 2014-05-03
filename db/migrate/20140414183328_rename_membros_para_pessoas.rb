class RenameMembrosParaPessoas < ActiveRecord::Migration
  def change
    rename_table :membros, :pessoas
    rename_table :relacoes_membro_grupo, :relacoes_pessoa_grupo
    rename_column :relacoes_pessoa_grupo, :grupo_id, :grupo_id
  end
end
