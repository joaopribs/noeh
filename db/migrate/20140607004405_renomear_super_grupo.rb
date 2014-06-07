class RenomearSuperGrupo < ActiveRecord::Migration
  def change
    rename_column :grupos, :eh_super_grupo, :tem_encontros
  end
end
