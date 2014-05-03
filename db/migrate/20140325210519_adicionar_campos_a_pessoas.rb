class AdicionarCamposAPessoas < ActiveRecord::Migration
  def change
    add_column :pessoas, :eh_super_admin, :boolean
  end
end
