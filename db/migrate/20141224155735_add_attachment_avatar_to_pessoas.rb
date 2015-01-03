class AddAttachmentAvatarToPessoas < ActiveRecord::Migration
  def self.up
    change_table :pessoas do |t|
      t.attachment :avatar
    end
  end

  def self.down
    remove_attachment :pessoas, :avatar
  end
end
