class AdicionarCorAConjuntoPessoas < ActiveRecord::Migration
  def change
    remove_column :conjuntos_pessoas, :cor
    add_column :conjuntos_pessoas, :cor_id, :integer
  end
end
