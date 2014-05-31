#encoding: utf-8

class AdicionarDenominacaoDefault < ActiveRecord::Migration
  def change
    change_column :encontros, :denominacao_conjuntos_permanentes, :string, default: "Círculo"
  end
end
