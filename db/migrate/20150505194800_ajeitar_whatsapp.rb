class AjeitarWhatsapp < ActiveRecord::Migration
  def change
  	remove_column :pessoas, :whatsapp, :string
  	add_column :telefones, :eh_whatsapp, :boolean
  end
end
