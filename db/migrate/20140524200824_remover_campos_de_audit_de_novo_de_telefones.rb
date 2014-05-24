class RemoverCamposDeAuditDeNovoDeTelefones < ActiveRecord::Migration
  def change
    remove_column :telefones, :quem_criou_id
    remove_column :telefones, :quem_editou_id
    remove_column :telefones, :quem_deletou_id
    remove_column :telefones, :quando_deletou
  end
end
