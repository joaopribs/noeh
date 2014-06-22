class AjeitarInstrumentos < ActiveRecord::Migration
  def change
    drop_table :relacoes_pessoa_instrumento
    add_column :instrumentos, :pessoa_id, :integer
  end
end
