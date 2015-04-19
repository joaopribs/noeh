class AdicionarIdAppFacebook < ActiveRecord::Migration
  def change
  	add_column :pessoas, :id_app_facebook, :string
  end
end
