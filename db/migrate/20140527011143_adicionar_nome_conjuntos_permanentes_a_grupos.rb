class AdicionarNomeConjuntosPermanentesAGrupos < ActiveRecord::Migration
  def change
    add_column :grupos, :nome_conjunto_permanente, :string
  end
end
