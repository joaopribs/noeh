class RemoverEncontroPadraoDeGrupos < ActiveRecord::Migration
  def change
    remove_column :grupos, :encontro_padrao_id
  end
end
