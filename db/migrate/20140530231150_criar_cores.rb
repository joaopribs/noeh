class CriarCores < ActiveRecord::Migration
  def change
    create_table :cores do |t|
      t.string :cor
      t.string :cor_contraste
    end
  end
end
