class RenomearCamposDeEncontro < ActiveRecord::Migration
  def change
    rename_column :encontros, :data_inicio_trabalho, :data_liberacao
    rename_column :encontros, :data_fim_trabalho, :data_fechamento
  end
end
