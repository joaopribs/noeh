#encoding: utf-8

class ConjuntoPessoas < ActiveRecord::Base

  self.table_name = :conjuntos_pessoas
  self.inheritance_column = :tipo

  default_scope {
    order(:nome)
  }

  has_many :relacoes_pessoa_conjunto, class_name: 'RelacaoPessoaConjunto', dependent: :destroy
  has_many :pessoas, through: :relacoes_pessoa_conjunto

  belongs_to :cor
  belongs_to :encontro

  def tipo_do_conjunto
    if self.tipo == "ConjuntoPermanente"
      return self.encontro.denominacao_conjuntos_permanentes
    else
      return self.tipo
    end
  end

  def coordenadores
    pessoas = self.relacoes_pessoa_conjunto.where(eh_coordenador: true).collect{|r| r.pessoa}

    pessoas_retornar = pessoas.select{|p| p.conjuge.nil?} + pessoas.select{|p| p.conjuge.present?}

    return pessoas_retornar
  end

end
