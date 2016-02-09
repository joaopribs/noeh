class CriarParentesco < ActiveRecord::Migration
  def change
  	create_table :paretesco do |t|
  		t.integer :pessoa_id
  		t.integer :outra_pessoa_id
  		t.string :parentesco
      t.timestamps
		end
  end
end
