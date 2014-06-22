#encoding: utf-8

class Instrumento < ActiveRecord::Base

  belongs_to :pessoa

  validates :nome, :presence => {:message => "Obrigatório"}

end