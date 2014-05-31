class CriarRelacaoPessoaConjunto < ActiveRecord::Migration
  def change
    create_table :relacoes_pessoa_conjunto do |t|
      t.integer :pessoa_id
      t.integer :conjunto_pessoas_id
      t.boolean :eh_coordenador
      t.timestamps
    end
  end
end
