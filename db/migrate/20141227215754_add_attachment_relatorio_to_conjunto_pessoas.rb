class AddAttachmentRelatorioToConjuntoPessoas < ActiveRecord::Migration
  def self.up
    change_table :conjuntos_pessoas do |t|
      t.attachment :relatorio
    end
  end

  def self.down
    remove_attachment :conjuntos_pessoas, :relatorio
  end
end
