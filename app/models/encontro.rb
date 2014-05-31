#encoding: utf-8

class Encontro < ActiveRecord::Base

  has_many :conjuntos_permanentes, class_name: 'ConjuntoPermanente', dependent: :destroy
  has_many :equipes, dependent: :destroy

  belongs_to :grupo

  validates :nome, :presence => {:message => "Obrigatório"}, unless: :eh_padrao
  validates :data_inicio, :presence => {:message => "Obrigatório"}, unless: :eh_padrao
  validates :data_termino, :presence => {:message => "Obrigatório"}, unless: :eh_padrao

  def eh_padrao
    return self.padrao == true
  end

  def data
    if self.data_inicio.present? && self.data_termino.present?
        return "#{self.data_inicio.strftime("%d/%m/%Y")} - #{self.data_termino.strftime("%d/%m/%Y")}"
    elsif self.data_inicio.present?
      return self.data_inicio.strftime("%d/%m/%Y")
    elsif self.data_termino.present?
      return self.data_termino.strftime("%d/%m/%Y")
    end

    return nil
  end


end
