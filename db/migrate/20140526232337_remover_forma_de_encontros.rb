class RemoverFormaDeEncontros < ActiveRecord::Migration
  def change
    drop_table :forma_de_encontros
  end
end
