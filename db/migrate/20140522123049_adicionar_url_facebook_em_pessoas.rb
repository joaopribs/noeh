class AdicionarUrlFacebookEmPessoas < ActiveRecord::Migration
  def change
    add_column :pessoas, :url_facebook, :string
  end
end
