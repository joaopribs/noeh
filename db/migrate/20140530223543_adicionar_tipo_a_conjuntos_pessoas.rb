class AdicionarTipoAConjuntosPessoas < ActiveRecord::Migration
  def change
    add_column :conjuntos_pessoas, :tipo, :string
  end
end
