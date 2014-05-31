class ColocarEncontrosEmEquipesEConjuntosPermanentes < ActiveRecord::Migration
  def change
    remove_column :equipes, :grupo_id
    add_column :equipes, :encontro_id, :integer
    add_column :conjuntos_permanentes, :encontro_id, :integer
  end
end
