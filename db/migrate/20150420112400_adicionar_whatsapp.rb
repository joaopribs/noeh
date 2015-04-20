class AdicionarWhatsapp < ActiveRecord::Migration
  def change
  	add_column :pessoas, :whatsapp, :string
  end
end
