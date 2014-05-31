class RemoverTodosOsAudits < ActiveRecord::Migration
  def change
    remove_column :conjuntos_permanentes, :quem_criou_id
    remove_column :conjuntos_permanentes, :quem_editou_id

    remove_column :encontros, :quem_criou_id
    remove_column :encontros, :quem_editou_id

    remove_column :equipes, :quem_criou_id
    remove_column :equipes, :quem_editou_id

    remove_column :grupos, :quem_criou_id
    remove_column :grupos, :quem_editou_id

    remove_column :pessoas, :quem_criou_id
    remove_column :pessoas, :quem_editou_id

    remove_column :relacoes_pessoa_grupo, :quem_criou_id
    remove_column :relacoes_pessoa_grupo, :quem_editou_id
  end
end
