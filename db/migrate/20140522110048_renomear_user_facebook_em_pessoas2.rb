class RenomearUserFacebookEmPessoas2 < ActiveRecord::Migration
  def change
    rename_column :pessoas, :user_facebook, :nome_facebook
  end
end
