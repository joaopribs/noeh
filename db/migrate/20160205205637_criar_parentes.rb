class CriarParentes < ActiveRecord::Migration
  def change
  	create_table :parentes do |t|
  		t.integer :pessoa_id
  		t.integer :outra_pessoa_id
  		t.string :parentesco
      t.timestamps
    end
  end
end
