class AdicionarConjugeParaPessoa < ActiveRecord::Migration
  def change
    add_column :pessoas, :conjuge_id, :integer, references: :pessoas
  end
end
