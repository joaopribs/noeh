class CriarInstrumentos < ActiveRecord::Migration
  def change
    create_table :instrumentos do |t|
      t.integer :pessoa_id
      t.integer :nome
      t.timestamps
    end
  end
end
