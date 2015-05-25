class CriarProblemas < ActiveRecord::Migration
  def change
  	create_table :problemas do |t|
      t.integer :problema
      t.timestamps
    end
  end
end
