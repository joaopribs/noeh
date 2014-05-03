class AdicionarComplementoAPessoas < ActiveRecord::Migration
  def change
    add_column :pessoas, :complemento, :string
  end
end
