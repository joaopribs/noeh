#encoding: utf-8

class SetarNomeConjuntosPermanentesDefaultEmGrupos < ActiveRecord::Migration
  def change
    change_column :grupos, :nome_conjunto_permanente, :string, default: "Círculo"
  end
end
