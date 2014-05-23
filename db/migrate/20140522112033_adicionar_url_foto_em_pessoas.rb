class AdicionarUrlFotoEmPessoas < ActiveRecord::Migration
  def change
    add_column :pessoas, :url_foto, :string
  end
end
