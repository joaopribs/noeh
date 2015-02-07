eclass AddEquipePadraoRelacionadaToConjuntoPessoas < ActiveRecord::Migration
  def change
  	add_column :conjuntos_pessoas, :equipe_padrao_relacionada, :integer, references: :conjuntos_pessoas
  end
end
