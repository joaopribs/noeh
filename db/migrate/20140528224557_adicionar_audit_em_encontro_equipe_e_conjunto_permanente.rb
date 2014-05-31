class AdicionarAuditEmEncontroEquipeEConjuntoPermanente < ActiveRecord::Migration
  def change
    add_column :encontros, :quem_criou_id, :integer
    add_column :encontros, :quem_editou_id, :integer
    add_column :encontros, :quem_deletou_id, :integer
    add_column :encontros, :quando_deletou, :datetime

    add_column :equipes, :quem_criou_id, :integer
    add_column :equipes, :quem_editou_id, :integer
    add_column :equipes, :quem_deletou_id, :integer
    add_column :equipes, :quando_deletou, :datetime

    add_column :conjuntos_permanentes, :quem_criou_id, :integer
    add_column :conjuntos_permanentes, :quem_editou_id, :integer
    add_column :conjuntos_permanentes, :quem_deletou_id, :integer
    add_column :conjuntos_permanentes, :quando_deletou, :datetime
  end
end
