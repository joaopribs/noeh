#encoding: utf-8

class Telefone < ActiveRecord::Base
  belongs_to :pessoa

  validates :telefone, :presence => {:message => "Obrigatório"}
  validates :operadora, :presence => {:message => "Obrigatório"}
end
