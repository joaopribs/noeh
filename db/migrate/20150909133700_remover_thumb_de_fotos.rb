class RemoverThumbDeFotos < ActiveRecord::Migration
  def change
    remove_column :fotos, :thumb_file_name, :string
    remove_column :fotos, :thumb_content_type, :string
    remove_column :fotos, :thumb_file_size, :integer
    remove_column :fotos, :thumb_updated_at, :datetime
  end
end
