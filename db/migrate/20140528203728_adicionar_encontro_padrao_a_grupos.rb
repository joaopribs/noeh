class AdicionarEncontroPadraoAGrupos < ActiveRecord::Migration
  def change
    add_column :grupos, :encontro_padrao_id, :integer
  end
end
