class AdicionarDeNovoCamposDeAuditEmTelefones < ActiveRecord::Migration
  def change
    add_column :telefones, :quem_criou_id, :integer
    add_column :telefones, :quem_editou_id, :integer
    add_column :telefones, :quem_deletou_id, :integer
    add_column :telefones, :quando_deletou, :datetime
  end
end
