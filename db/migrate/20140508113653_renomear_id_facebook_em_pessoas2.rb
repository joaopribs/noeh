class RenomearIdFacebookEmPessoas2 < ActiveRecord::Migration
  def change
    rename_column :pessoas, :id_facebook, :user_facebook
  end
end
