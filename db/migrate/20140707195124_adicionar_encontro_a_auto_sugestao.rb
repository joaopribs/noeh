class AdicionarEncontroAAutoSugestao < ActiveRecord::Migration
  def change
    add_column :auto_sugestao, :encontro_id, :integer
  end
end
