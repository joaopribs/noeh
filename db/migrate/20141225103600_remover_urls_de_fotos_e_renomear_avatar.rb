class RemoverUrlsDeFotosERenomearAvatar < ActiveRecord::Migration
  def change
    remove_column :pessoas, :url_foto_grande, :string
    remove_column :pessoas, :url_foto_pequena, :string
    rename_column :pessoas, :avatar_file_name, :foto_grande_file_name
    rename_column :pessoas, :avatar_content_type, :foto_grande_content_type
    rename_column :pessoas, :avatar_file_size, :foto_grande_file_size
    rename_column :pessoas, :avatar_updated_at, :foto_grande_updated_at
  end
end
