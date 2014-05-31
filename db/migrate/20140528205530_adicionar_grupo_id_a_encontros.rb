class AdicionarGrupoIdAEncontros < ActiveRecord::Migration
  def change
    add_column :encontros, :grupo_id, :integer
  end
end
