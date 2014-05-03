class AddConjugeToPessoa < ActiveRecord::Migration
  def change
    add_reference :pessoas, :conjuge, index: true, class: "Pessoa"
  end
end
