#encoding: utf-8

class RecomendacaoEquipe < ActiveRecord::Base

  self.table_name = :recomendacoes_equipes

  belongs_to :pessoa
  belongs_to :equipe, foreign_key: "conjunto_pessoas_id"

end
