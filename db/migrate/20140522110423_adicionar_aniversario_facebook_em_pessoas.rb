class AdicionarAniversarioFacebookEmPessoas < ActiveRecord::Migration
  def change
    add_column :pessoas, :aniversario_facebook, :string
  end
end
