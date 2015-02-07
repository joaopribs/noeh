class GrupoPodeVerEquipesDeOutrosGrupos < ActiveRecord::Base
  belongs_to :grupo, foreign_key: "grupo_id", class_name: "Grupo"
  belongs_to :outro_grupo, foreign_key: "outro_grupo_id", class_name: "Grupo"
end