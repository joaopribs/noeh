class RenomearAniversarioFacebookEmPessoas < ActiveRecord::Migration
  def change
    rename_column :pessoas, :aniversario_facebook, :email_facebook
  end
end
