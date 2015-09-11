class CriarFotos < ActiveRecord::Migration
  def change
  	create_table :fotos do |t|
      t.integer :pessoa_id
      t.string :foto_file_name
      t.string :foto_content_type
      t.integer :foto_file_size
      t.datetime :foto_updated_at
      t.string :thumb_file_name
      t.string :thumb_content_type
      t.integer :thumb_file_size
      t.datetime :thumb_updated_at
      t.timestamps
    end
  end
end
