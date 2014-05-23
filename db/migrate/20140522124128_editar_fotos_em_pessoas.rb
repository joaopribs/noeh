class EditarFotosEmPessoas < ActiveRecord::Migration
  def change
    rename_column :pessoas, :url_foto, :url_foto_grande
    add_column :pessoas, :url_foto_pequena, :string
  end
end
