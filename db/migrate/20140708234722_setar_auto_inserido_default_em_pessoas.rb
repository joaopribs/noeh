class SetarAutoInseridoDefaultEmPessoas < ActiveRecord::Migration
  def change
    change_column :pessoas, :auto_inserido, :boolean, default: false
  end
end
