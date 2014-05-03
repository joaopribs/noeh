class RenomearCamposDePessoas < ActiveRecord::Migration
  def change
    rename_column :pessoas, :idFacebook, :id_facebook
    rename_column :pessoas, :nomeSimplificado, :nome_simplificado
  end
end
