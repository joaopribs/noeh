class RenamePessoas < ActiveRecord::Migration
  def change
    rename_table :pessoas, :membros
  end
end
