class AdicionarConjugeAAutoSugestao < ActiveRecord::Migration
  def change
  	add_column :auto_sugestao, :conjuge_id, :integer, references: :pessoas
  end
end
