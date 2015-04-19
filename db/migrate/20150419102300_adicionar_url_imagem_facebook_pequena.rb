class AdicionarUrlImagemFacebookPequena < ActiveRecord::Migration
  def change
  	add_column :pessoas, :url_imagem_facebook_pequena, :string
  end
end
