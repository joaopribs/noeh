class CreateGrupoPodeVerEquipesDeOutroGrupo < ActiveRecord::Migration
  def change
    create_table :grupo_pode_ver_equipes_de_outro_grupos do |t|
      t.integer :grupo_id
      t.integer :outro_grupo_id
      t.timestamps
    end
  end
end
