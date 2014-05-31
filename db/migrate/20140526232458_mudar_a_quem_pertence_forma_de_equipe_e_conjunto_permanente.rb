class MudarAQuemPertenceFormaDeEquipeEConjuntoPermanente < ActiveRecord::Migration
  def change
    rename_column :forma_de_conjunto_permanentes, :forma_de_encontro_id, :grupo_id
    rename_column :forma_de_equipes, :forma_de_encontro_id, :grupo_id
  end
end
