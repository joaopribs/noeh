class RenomearPessoaIdIdEmTelefones < ActiveRecord::Migration
  def change
    rename_column :telefones, :pessoa_id_id, :pessoa_id
  end
end
