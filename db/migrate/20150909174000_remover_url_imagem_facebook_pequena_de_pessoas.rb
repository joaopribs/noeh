class RemoverUrlImagemFacebookPequenaDePessoas < ActiveRecord::Migration
  def change
    remove_column :pessoas, :url_imagem_facebook_pequena, :string
  end
end
