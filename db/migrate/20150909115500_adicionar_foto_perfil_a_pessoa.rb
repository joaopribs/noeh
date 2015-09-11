class AdicionarFotoPerfilAPessoa < ActiveRecord::Migration
  def change
    add_column :pessoas, :foto_perfil_id, :integer
  end
end
