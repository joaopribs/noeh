class CriarPadroesRelacionamento < ActiveRecord::Migration
  def change
  	create_table :padroes_relacionamento do |t|
  		t.string :relacionamento_masculino
  		t.string :relacionamento_feminino
  		t.integer :relacionamento_oposto_id
      t.timestamps
		end
  end
end
