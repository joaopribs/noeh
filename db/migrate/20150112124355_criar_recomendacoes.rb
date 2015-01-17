class CriarRecomendacoes < ActiveRecord::Migration
  def change
    create_table :recomendacoes_equipes do |t|
      t.integer :conjunto_pessoas_id
      t.integer :pessoa_id
      t.integer :posicao
      t.timestamps
    end

    create_table :recomendacoes_do_coordenador_permanente do |t|
      t.integer :conjunto_pessoas_id
      t.integer :pessoa_id
      t.boolean :recomenda_pra_coordenador
      t.string :comentario
      t.timestamps
    end
  end
end
