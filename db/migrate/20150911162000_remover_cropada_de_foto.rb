class RemoverCropadaDeFoto < ActiveRecord::Migration
  def change
    remove_column :fotos, :cropada, :boolean
  end
end
