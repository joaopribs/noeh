class AdicionarNomeACor < ActiveRecord::Migration
  def change
    add_column :cores, :nome, :string
    rename_column :cores, :cor, :hex_cor
    rename_column :cores, :cor_contraste, :hex_contraste
  end
end
