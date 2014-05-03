#encoding: utf-8

class Grupo < ActiveRecord::Base
  include Auditavel
  default_scope {
    order(:nome)
  }

  has_many :relacoes_pessoa_grupo, class_name: 'RelacaoPessoaGrupo', dependent: :destroy
  has_many :pessoas, through: :relacoes_pessoa_grupo

  validates :nome, :presence => {:message => "Obrigatório"}
  validates :eh_super_grupo, :inclusion => {:in => [true, false], :message => "Obrigatório"}

  def coordenadores
    return self.relacoes_pessoa_grupo.where(eh_coordenador: true).collect{|r| r.pessoa}
  end

end
