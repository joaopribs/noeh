#encoding: utf-8

class Grupo < ActiveRecord::Base

  extend FriendlyId

  before_create {
    self.encontro_padrao = Encontro.new({nome: "Padrão", padrao: true})
  }

  default_scope {
    order(:nome)
  }

  friendly_id :nome, use: :slugged

  has_many :relacoes_pessoa_grupo, class_name: 'RelacaoPessoaGrupo', dependent: :destroy
  has_many :pessoas, through: :relacoes_pessoa_grupo
  has_many :encontros, -> { where padrao: false}, dependent: :destroy

  has_one :encontro_padrao, -> { where padrao: true}, class_name: 'Encontro', dependent: :destroy

  validates :nome, :presence => {:message => "Obrigatório"}
  validates :eh_super_grupo, :inclusion => {:in => [true, false], :message => "Obrigatório"}

  def coordenadores
    return self.relacoes_pessoa_grupo.where(eh_coordenador: true).collect{|r| r.pessoa}
  end

end
