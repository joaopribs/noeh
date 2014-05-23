class AdicionarUltimoLoginEmPessoas < ActiveRecord::Migration
  def change
    add_column :pessoas, :ultimo_login, :datetime
  end
end
