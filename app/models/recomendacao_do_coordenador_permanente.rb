#encoding: utf-8

class RecomendacaoDoCoordenadorPermanente < ActiveRecord::Base

  self.table_name = :recomendacoes_do_coordenador_permanente

  belongs_to :pessoa
  belongs_to :conjunto_permanente, foreign_key: "conjunto_pessoas_id"

end
