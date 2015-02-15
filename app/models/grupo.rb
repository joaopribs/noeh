#encoding: utf-8

class Grupo < ActiveRecord::Base

  extend FriendlyId

  before_create {
    if self.tem_encontros
      self.encontro_padrao = Encontro.new({nome: "Padrão", padrao: true})
    end
  }

  before_destroy { outros_grupos_que_pode_ver_equipes.clear }

  default_scope { order(:nome) }

  friendly_id :nome, use: :slugged

  has_many :relacoes_pessoa_grupo, -> {where 'relacoes_pessoa_grupo.deixou_de_participar_em IS NULL'}, class_name: 'RelacaoPessoaGrupo', dependent: :destroy
  has_many :pessoas, -> {reorder 'relacoes_pessoa_grupo.eh_coordenador DESC, pessoas.nome ASC'}, through: :relacoes_pessoa_grupo
  has_many :encontros, -> { where padrao: false}, dependent: :destroy
  has_many :auto_sugestoes, class_name: 'AutoSugestao', dependent: :destroy

  # Autorrelacionamento bidirecional
  has_many :outros_grupos_que_pode_ver_equipes_relacionamento, foreign_key: 'grupo_id', class_name: 'GrupoPodeVerEquipesDeOutrosGrupos'
  has_many :outros_grupos_que_pode_ver_equipes, through: :outros_grupos_que_pode_ver_equipes_relacionamento, source: :outro_grupo, dependent: :destroy
  has_many :pode_ser_visto_por_outros_grupos_relacionamento, foreign_key: 'outro_grupo_id', class_name: 'GrupoPodeVerEquipesDeOutrosGrupos'
  has_many :pode_ser_visto_por_outros_grupos, through: :pode_ser_visto_por_outros_grupos_relacionamento, source: :grupo, dependent: :destroy

  has_one :encontro_padrao, -> { where padrao: true}, class_name: 'Encontro', dependent: :destroy

  validates :nome, :presence => {:message => "Obrigatório"}
  validates :nome, :uniqueness => {:message => "Já há grupo com esse nome", :case_sensitive => false}
  validates :tem_encontros, :inclusion => {:in => [true, false], :message => "Obrigatório"}

  def coordenadores
    return self.relacoes_pessoa_grupo.where(eh_coordenador: true).collect{|r| r.pessoa}
  end

  def ex_relacoes
    return self.relacoes_pessoa_grupo.unscoped.where("grupo_id = #{self.id} AND deixou_de_participar_em IS NOT NULL").order('deixou_de_participar_em DESC')
  end

  def pegar_pessoas array_ids
    pessoas = []

    if array_ids.present? && array_ids.count > 0
      array_ids.each do |id|
        pessoas << Pessoa.find(id)
      end
    end

    return pessoas
  end

  def ids_pessoas_a_confirmar
    auto_sugestoes = self.auto_sugestoes

    return auto_sugestoes.select{|a| a.conjuge == nil}.collect{|a| a.pessoa_id}.uniq
  end

  def auto_sugestoes_individuais_de_pessoa id_pessoa
    auto_sugestoes = self.auto_sugestoes

    return auto_sugestoes.select{|a| a.pessoa_id == id_pessoa && a.conjuge_id == nil}
  end

  def auto_sugestoes_de_casal id_pessoa
    auto_sugestoes = self.auto_sugestoes

    return auto_sugestoes.select{|a| (a.pessoa_id == id_pessoa || a.conjuge_id == id_pessoa) && a.conjuge_id != nil}
  end
end
