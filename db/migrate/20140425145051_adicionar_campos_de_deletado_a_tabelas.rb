class AdicionarCamposDeDeletadoATabelas < ActiveRecord::Migration
  def change
    add_column :pessoas, :quem_deletou_id, :integer
    add_column :pessoas, :quando_deletou, :datetime
    add_column :grupos, :quem_deletou_id, :integer
    add_column :grupos, :quando_deletou, :datetime
    add_column :relacoes_pessoa_grupo, :quem_deletou_id, :integer
    add_column :relacoes_pessoa_grupo, :quando_deletou, :datetime
  end
end
