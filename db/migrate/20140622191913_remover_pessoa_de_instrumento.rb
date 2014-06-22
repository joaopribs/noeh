class RemoverPessoaDeInstrumento < ActiveRecord::Migration
  def change
    remove_column :instrumentos, :pessoa_id
  end
end
