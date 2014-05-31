class RemoverEquipesEConjuntosPermanentes < ActiveRecord::Migration
  def change
    drop_table :equipes
    drop_table :conjuntos_permanentes
  end
end
