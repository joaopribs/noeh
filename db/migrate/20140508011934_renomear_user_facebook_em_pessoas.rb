class RenomearUserFacebookEmPessoas < ActiveRecord::Migration
  def change
    rename_column :pessoas, :user_facebook, :id_facebook
  end
end
