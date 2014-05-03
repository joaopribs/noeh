class AdicionarSuperGrupo < ActiveRecord::Migration
  def change
    add_column :grupos, :eh_super_grupo, :boolean, default: false
  end
end
