class AdicionarTipoACores < ActiveRecord::Migration
  def change
    add_column :cores, :tipo, :string
  end
end
