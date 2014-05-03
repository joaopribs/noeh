class CreatePastorais < ActiveRecord::Migration
  def change
    create_table :pastorais do |t|
      t.string :nome

      t.timestamps
    end
  end
end
