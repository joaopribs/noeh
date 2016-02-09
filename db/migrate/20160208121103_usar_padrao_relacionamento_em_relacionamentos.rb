class UsarPadraoRelacionamentoEmRelacionamentos < ActiveRecord::Migration
  def change
  	remove_column :relacionamentos, :relacionamento, :string
  	add_column :relacionamentos, :padrao_relacionamento_id, :integer
  end
end
