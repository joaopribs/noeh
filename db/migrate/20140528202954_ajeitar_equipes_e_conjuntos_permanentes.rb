class AjeitarEquipesEConjuntosPermanentes < ActiveRecord::Migration
  def change
    remove_column :forma_de_conjunto_permanentes, :cor
    rename_table :forma_de_conjunto_permanentes, :conjuntos_permanentes
    rename_table :forma_de_equipes, :equipes
  end
end
