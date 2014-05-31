class Cor < ActiveRecord::Base
  self.table_name = :cores

  default_scope {
    order(:nome)
  }

  validates_presence_of :nome, :hex_cor, :hex_contraste
end