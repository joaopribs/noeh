class RenomearGrupoQuePodeVerEquipesDeOutrosGrupos < ActiveRecord::Migration
  def change
    rename_table :grupo_pode_ver_equipes_de_outro_grupos, :grupo_pode_ver_equipes_de_outros_grupos
  end
end
