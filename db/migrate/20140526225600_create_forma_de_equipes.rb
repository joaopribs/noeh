class CreateFormaDeEquipes < ActiveRecord::Migration
  def change
    create_table :forma_de_equipes do |t|
      t.string :nome
      t.string :cor_cracha
      t.references :forma_de_encontro, index: true

      t.timestamps
    end
  end
end
