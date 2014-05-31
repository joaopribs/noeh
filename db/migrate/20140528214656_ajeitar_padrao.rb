class AjeitarPadrao < ActiveRecord::Migration
  def change
    remove_column :grupos, :padrao
    add_column :encontros, :padrao, :boolean, default: false
  end
end
