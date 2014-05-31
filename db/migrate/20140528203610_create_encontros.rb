class CreateEncontros < ActiveRecord::Migration
  def change
    create_table :encontros do |t|

      t.timestamps
    end
  end
end
