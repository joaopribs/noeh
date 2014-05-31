class CreateFormaDeConjuntoPermanentes < ActiveRecord::Migration
  def change
    create_table :forma_de_conjunto_permanentes do |t|
      t.string :nome
      t.string :cor
      t.references :forma_de_encontro, index: true

      t.timestamps
    end
  end
end
