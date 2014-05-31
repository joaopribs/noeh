class CreateEncontroPadraos < ActiveRecord::Migration
  def change
    create_table :encontros_padroes do |t|
      t.integer :grupo_id
      t.timestamps
    end
  end
end
