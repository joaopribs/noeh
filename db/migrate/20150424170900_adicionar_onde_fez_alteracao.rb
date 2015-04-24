class AdicionarOndeFezAlteracao < ActiveRecord::Migration
  def change
  	add_column :pessoas, :onde_fez_alteracao, :string
  end
end
