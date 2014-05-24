class CreateTelefones < ActiveRecord::Migration
  def change
    create_table :telefones do |t|
      t.string :telefone
      t.string :operadora
      t.references :pessoa_id, index: true

      t.timestamps
    end
  end
end
