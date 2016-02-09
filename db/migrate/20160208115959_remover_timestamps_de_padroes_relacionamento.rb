class RemoverTimestampsDePadroesRelacionamento < ActiveRecord::Migration
  def change
  	remove_column :padroes_relacionamento, :created_at, :timestamp
  	remove_column :padroes_relacionamento, :updated_at, :timestamp
  end
end
