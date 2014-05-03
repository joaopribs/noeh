class RemoveConjugeFromPessoa < ActiveRecord::Migration
  def change
    remove_reference :pessoas, :conjuge, index: true
  end
end
