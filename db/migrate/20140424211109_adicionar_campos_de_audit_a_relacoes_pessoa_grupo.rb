class AdicionarCamposDeAuditARelacoesPessoaGrupo < ActiveRecord::Migration
  def change
    add_column :relacoes_pessoa_grupo, :quem_criou_id, :integer
    add_column :relacoes_pessoa_grupo, :quem_editou_id, :integer
  end
end
