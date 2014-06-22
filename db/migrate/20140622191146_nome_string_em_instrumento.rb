class NomeStringEmInstrumento < ActiveRecord::Migration
  def change
    change_column :instrumentos, :nome, :string
  end
end
