class CriarConjuntoPessoas < ActiveRecord::Migration
  def change
    create_table :conjuntos_pessoas do |t|
      t.integer :encontro_id
      t.string :nome
      t.string :cor
      t.timestamps
    end
  end
end
