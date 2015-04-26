#encoding: utf-8

class Encontro < ActiveRecord::Base

  before_create {
    self.coordenacao_encontro = CoordenacaoEncontro.new({nome: "Coordenação"})
  }

  default_scope {
    order('data_inicio DESC')
  }

  has_many :conjuntos_permanentes, class_name: 'ConjuntoPermanente', dependent: :delete_all
  has_many :equipes, dependent: :delete_all
  has_many :conjuntos, class_name: 'ConjuntoPessoas', dependent: :delete_all
  has_one :coordenacao_encontro, dependent: :delete

  belongs_to :grupo

  validates :nome, :presence => {:message => "Obrigatório"}, unless: :eh_padrao
  validates :data_inicio, :presence => {:message => "Obrigatório"}, unless: :eh_padrao
  validates :data_termino, :presence => {:message => "Obrigatório"}, unless: :eh_padrao

  def eh_padrao
    return self.padrao == true
  end

  def coordenadores
    return self.coordenacao_encontro.pessoas
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

  def conjuntos_ordenados
    return conjuntos.select{|c| c.tipo == 'Equipe' || c.tipo == 'CoordenacaoEncontro'}.sort_by{|a| a.nome} + conjuntos.select{|c| c.tipo == 'ConjuntoPermanente'}.sort_by{|a| a.nome}
  end

  def conjuntos_que_poderia_adicionar_pessoa
    conjuntos = self.conjuntos.reject{|conjunto| conjunto.tipo == 'CoordenacaoEncontro'}

    conjuntos = conjuntos.select{|c| c.tipo == 'Equipe'}.sort_by{|a| a.nome} + conjuntos.select{|c| c.tipo == 'ConjuntoPermanente'}.sort_by{|a| a.nome}

    return conjuntos
  end

end
