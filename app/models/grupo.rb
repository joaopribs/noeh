#encoding: utf-8

class Grupo < ActiveRecord::Base

  extend FriendlyId

  before_create {
    if self.tem_encontros
      self.encontro_padrao = Encontro.new({nome: "Padrão", padrao: true})
    end
  }

  default_scope {
    order(:nome)
  }

  friendly_id :nome, use: :slugged

  has_many :relacoes_pessoa_grupo, class_name: 'RelacaoPessoaGrupo', dependent: :destroy
  has_many :pessoas,  -> {reorder 'relacoes_pessoa_grupo.eh_coordenador DESC, pessoas.nome ASC'}, through: :relacoes_pessoa_grupo
  has_many :encontros, -> { where padrao: false}, dependent: :destroy

  has_one :encontro_padrao, -> { where padrao: true}, class_name: 'Encontro', dependent: :destroy

  validates :nome, :presence => {:message => "Obrigatório"}
  validates :nome, :uniqueness => {:message => "Já há grupo com esse nome", :case_sensitive => false}
  validates :tem_encontros, :inclusion => {:in => [true, false], :message => "Obrigatório"}

  def coordenadores
    return self.relacoes_pessoa_grupo.where(eh_coordenador: true).collect{|r| r.pessoa}
  end

  def ex_participantes
    return self.relacoes_pessoa_grupo.unscoped.where('deixou_de_participar_em IS NOT NULL').collect{|r| r.pessoa}
  end
end
