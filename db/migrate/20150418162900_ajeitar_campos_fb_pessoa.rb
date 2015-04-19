class AjeitarCamposFbPessoa < ActiveRecord::Migration
  def change
  	add_column :pessoas, :usuario_facebook, :string
  	remove_column :pessoas, :nome_facebook, :string
  	remove_column :pessoas, :email_facebook, :string
  end
end
