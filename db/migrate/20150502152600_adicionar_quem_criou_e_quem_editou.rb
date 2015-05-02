class AdicionarQuemCriouEQuemEditou < ActiveRecord::Migration
  def change
  	add_column :pessoas, :quem_criou, :integer
  	add_column :pessoas, :quem_editou, :integer
  end
end
