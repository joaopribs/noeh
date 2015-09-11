class RemoverFotosDePessoas < ActiveRecord::Migration
  def change
    remove_column :pessoas, :foto_grande_file_name, :string
    remove_column :pessoas, :foto_grande_content_type, :string
    remove_column :pessoas, :foto_grande_file_size, :integer
    remove_column :pessoas, :foto_grande_updated_at, :datetime
    remove_column :pessoas, :foto_pequena_file_name, :string
    remove_column :pessoas, :foto_pequena_content_type, :string
    remove_column :pessoas, :foto_pequena_file_size, :integer
    remove_column :pessoas, :foto_pequena_updated_at, :datetime
  end
end
