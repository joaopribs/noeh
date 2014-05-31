class REmoverGrupoDeConjuntoPermanente < ActiveRecord::Migration
  def change
    remove_column :conjuntos_permanentes, :grupo_id
  end
end
