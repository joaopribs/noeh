class AdicionarCamposDeAuditAPessoas < ActiveRecord::Migration
  def change
    add_column :pessoas, :quem_criou_id, :integer
    add_column :pessoas, :quem_editou_id, :integer
  end
end
