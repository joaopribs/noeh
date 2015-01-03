class AdicionarUrlImagemFacebookAPessoa < ActiveRecord::Migration
  def change
    add_column :pessoas, :url_imagem_facebook, :string
  end
end
