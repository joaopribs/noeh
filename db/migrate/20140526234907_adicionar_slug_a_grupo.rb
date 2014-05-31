class AdicionarSlugAGrupo < ActiveRecord::Migration
  def change
    add_column :grupos, :slug, :string, unique: true
  end
end
