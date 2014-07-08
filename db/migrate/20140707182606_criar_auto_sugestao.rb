class CriarAutoSugestao < ActiveRecord::Migration
  def change
    create_table :auto_sugestao do |t|
      t.integer :pessoa_id
      t.integer :grupo_id
      t.string :sugestao
      t.timestamps
    end
  end
end
