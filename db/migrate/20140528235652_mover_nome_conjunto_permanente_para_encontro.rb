class MoverNomeConjuntoPermanenteParaEncontro < ActiveRecord::Migration
  def change
    remove_column :grupos, :nome_conjunto_permanente
    add_column :encontros, :denominacao_conjuntos_permanentes, :string
  end
end
