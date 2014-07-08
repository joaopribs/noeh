class AdicionarAutoInserido < ActiveRecord::Migration
  def change
    add_column :pessoas, :auto_inserido, :boolean
    add_column :relacoes_pessoa_grupo, :auto_inserido, :boolean
    add_column :relacoes_pessoa_conjunto, :auto_inserido, :boolean
  end
end
