class RemoverCamposDeDelete < ActiveRecord::Migration
  def change
    remove_column :conjuntos_permanentes, :quem_deletou_id
    remove_column :conjuntos_permanentes, :quando_deletou

    remove_column :encontros, :quem_deletou_id
    remove_column :encontros, :quando_deletou

    remove_column :equipes, :quem_deletou_id
    remove_column :equipes, :quando_deletou

    remove_column :grupos, :quem_deletou_id
    remove_column :grupos, :quando_deletou

    remove_column :pessoas, :quem_deletou_id
    remove_column :pessoas, :quando_deletou

    remove_column :relacoes_pessoa_grupo, :quem_deletou_id
    remove_column :relacoes_pessoa_grupo, :quando_deletou
  end
end
