#encoding: utf-8

class Telefone < ActiveRecord::Base
  belongs_to :pessoa

  validates :telefone, :presence => {:message => "Obrigatório"}
  validates :operadora, :presence => {:message => "Obrigatório"}

  validate :validate_telefone

  def validate_telefone
  	if self.telefone.present? && (self.telefone =~ /\(\d{2}\)\s\d{4}-\d{4}/) == nil && (self.telefone =~ /\(\d{2}\)\s\d{5}-\d{4}/) == nil
      errors.add(:telefone, "Formato inválido")
    end
  end

end
