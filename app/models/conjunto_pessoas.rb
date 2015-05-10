#encoding: utf-8

class ConjuntoPessoas < ActiveRecord::Base

  self.table_name = :conjuntos_pessoas
  self.inheritance_column = :tipo

  has_many :relacoes_pessoa_conjunto, class_name: 'RelacaoPessoaConjunto', dependent: :destroy
  has_many :pessoas, -> {reorder "relacoes_pessoa_conjunto.eh_coordenador DESC, CASE WHEN pessoas.conjuge_id IS NULL THEN 0 WHEN pessoas.conjuge_id IS NOT NULL AND NOT EXISTS (SELECT * FROM relacoes_pessoa_conjunto rpc WHERE rpc.pessoa_id = pessoas.conjuge_id AND rpc.conjunto_pessoas_id = relacoes_pessoa_conjunto.conjunto_pessoas_id) THEN 0 ELSE 1 END ASC, pessoas.nome ASC"}, through: :relacoes_pessoa_conjunto

  belongs_to :cor
  belongs_to :encontro

  default_scope {
    joins(:encontro).order('encontros.data_inicio DESC, conjuntos_pessoas.nome ASC')
  }

  validates :nome, :presence => {:message => "Obrigatório"}

  def tipo_do_conjunto
    if self.tipo == "ConjuntoPermanente"
      return self.encontro.denominacao_conjuntos_permanentes
    else
      return self.tipo
    end
  end

  def coordenadores
    pessoas_retornar = []

    pessoas = self.relacoes_pessoa_conjunto.where(eh_coordenador: true).collect{|r| r.pessoa}

    if pessoas.count > 0
      pessoas_retornar = pessoas.select{|p| p.conjuge.nil?} + pessoas.select{|p| p.conjuge.present?}
    end

    return pessoas_retornar
  end

  def as_json(options={})
    super(options.merge({:methods => :tipo}))
  end

end
