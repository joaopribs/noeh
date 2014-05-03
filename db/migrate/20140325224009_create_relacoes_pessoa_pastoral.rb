class CreateRelacoesPessoaPastoral < ActiveRecord::Migration
  def change
    create_table :relacoes_pessoa_pastoral do |t|
      t.boolean :eh_coordenador

      t.references :pastoral
      t.references :membro

      t.timestamps
    end
  end
end
