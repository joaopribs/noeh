class AjeitarCores < ActiveRecord::Migration
  def change
    remove_column :cores, :tipo
    add_column :cores, :de_equipe, :boolean
    add_column :cores, :de_conjunto_permanente, :boolean
  end
end
