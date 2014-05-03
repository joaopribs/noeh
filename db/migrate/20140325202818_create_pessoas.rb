class CreatePessoas < ActiveRecord::Migration
  def change
    create_table :pessoas do |t|
      t.string :idFacebook
      t.string :nome
      t.string :nomeSimplificado
      t.date :nascimento
      t.string :rua
      t.string :numero
      t.string :bairro
      t.string :cidade
      t.string :estado
      t.string :cep
      t.boolean :ehHomem
      t.string :email

      t.timestamps
    end
  end
end
