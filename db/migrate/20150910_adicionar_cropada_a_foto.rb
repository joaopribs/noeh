class AdicionarCropadaAFoto < ActiveRecord::Migration
  def change
    add_column :fotos, :cropada, :boolean
  end
end
