class AdicionarCamposDeAuditAGrupos < ActiveRecord::Migration
  def change
    add_column :grupos, :quem_criou_id, :integer
    add_column :grupos, :quem_editou_id, :integer
  end
end
