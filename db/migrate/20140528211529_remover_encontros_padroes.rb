class RemoverEncontrosPadroes < ActiveRecord::Migration
  def change
    drop_table :encontros_padroes
    add_column :grupos, :encontro_padrao_id, :integer
  end
end
