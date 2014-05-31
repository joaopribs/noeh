class AdicionarPadraoAGrupo < ActiveRecord::Migration
  def change
    add_column :grupos, :padrao, :boolean, default: false
  end
end
