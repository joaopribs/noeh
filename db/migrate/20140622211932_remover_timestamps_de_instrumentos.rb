class RemoverTimestampsDeInstrumentos < ActiveRecord::Migration
  def change
    remove_column :instrumentos, :created_at
    remove_column :instrumentos, :updated_at
  end
end
