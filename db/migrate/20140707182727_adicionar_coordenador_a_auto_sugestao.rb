class AdicionarCoordenadorAAutoSugestao < ActiveRecord::Migration
  def change
    add_column :auto_sugestao, :coordenador, :boolean
  end
end
