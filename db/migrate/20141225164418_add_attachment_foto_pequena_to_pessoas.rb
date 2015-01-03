class AddAttachmentFotoPequenaToPessoas < ActiveRecord::Migration
  def self.up
    change_table :pessoas do |t|
      t.attachment :foto_pequena
    end
  end

  def self.down
    remove_attachment :pessoas, :foto_pequena
  end
end
