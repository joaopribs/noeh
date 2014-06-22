class CriarRelacaoPessoaInstrumento < ActiveRecord::Migration
  def change
    create_table :relacoes_pessoa_instrumento do |t|
      t.integer :pessoa_id
      t.integer :instrumento_id
      t.timestamps
    end
  end
end
