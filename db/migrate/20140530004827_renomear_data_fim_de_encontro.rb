class RenomearDataFimDeEncontro < ActiveRecord::Migration
  def change
    rename_column :encontros, :data_fim, :data_termino
  end
end
