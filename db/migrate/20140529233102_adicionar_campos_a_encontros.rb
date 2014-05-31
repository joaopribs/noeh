class AdicionarCamposAEncontros < ActiveRecord::Migration
  def change
    add_column :encontros, :nome, :string
    add_column :encontros, :local, :string
    add_column :encontros, :tema, :string
    add_column :encontros, :data_inicio, :date
    add_column :encontros, :data_fim, :date
    add_column :encontros, :data_inicio_trabalho, :date
    add_column :encontros, :data_fim_trabalho, :date
  end
end
