#encoding: utf-8

class Pessoa < ActiveRecord::Base

  after_initialize :default_values

  before_save :atualizar_data

  default_scope { order(:nome) }

  attr_accessor :dia, :mes, :ano, :tem_facebook

  has_many :relacoes_pessoa_conjunto, class_name: 'RelacaoPessoaConjunto', dependent: :destroy
  has_many :conjuntos_pessoas, through: :relacoes_pessoa_conjunto, source: 'conjunto_pessoas'
  has_many :equipes, -> { where tipo: 'Equipe' }, through: :relacoes_pessoa_conjunto, source: 'conjunto_pessoas'
  has_many :conjuntos_permanentes, -> { where tipo: 'ConjuntoPermanente' }, through: :relacoes_pessoa_conjunto, source: 'conjunto_pessoas'
  has_many :relacoes_pessoa_grupo, class_name: 'RelacaoPessoaGrupo', dependent: :destroy
  has_many :grupos, through: :relacoes_pessoa_grupo
  has_many :telefones, dependent: :destroy
  has_many :instrumentos, dependent: :destroy

  belongs_to :conjuge, class_name: 'Pessoa', foreign_key: :conjuge_id, dependent: :destroy

  validates :nome, :presence => {:message => "Obrigatório"}
  validates :nome_usual, :presence => {:message => "Obrigatório"}
  validates :eh_homem, :inclusion => {:in => [true, false], :message => "Obrigatório"}
  validates :eh_super_admin, :inclusion => {:in => [true, false]}

  validate :validate_nascimento
  validate :validate_facebook
  validate :validate_email
  validate :validate_cep

  def self.pegar_pessoas array_ids
    pessoas = []

    if array_ids.present? && array_ids.count > 0
      array_ids.each do |id|
        pessoas << Pessoa.find(id)
      end
    end

    return pessoas
  end

  def self.url_imagem_sem_imagem tamanho
    if tamanho > 120
      url = "/assets/semfoto200.png"
    elsif tamanho > 80
      url = "/assets/semfoto100.png"
    else
      url = "/assets/semfoto50.png"
    end

    return url
  end

  def url_imagem tamanho
    if self.url_foto_pequena.present? || self.url_foto_grande.present?
      if tamanho < 80
        url = self.url_foto_pequena.present? ? self.url_foto_pequena : self.url_foto_grande
      else
        url = self.url_foto_grande.present? ? self.url_foto_grande : self.url_foto_pequena
      end
    else
      url = Pessoa.url_imagem_sem_imagem tamanho
    end

    return url
  end

  def label
    label = self.nome_usual
    if self.conjuge.present?
      label += " / #{self.conjuge.nome_usual}"
    end

    return label
  end

  def tem_informacoes_facebook
    return self.url_facebook.present? || self.nome_facebook.present? || self.email_facebook.present?
  end

  def eh_coordenador_de_grupo_de(outra_pessoa)
    relacoes = self.relacoes_pessoa_grupo.where(eh_coordenador: true)

    relacoes.each do |relacao|
      if relacao.grupo.pessoas.include? outra_pessoa
        return true
      end
    end

    return false
  end

  def eh_coordenador_de_grupo_que_tem_encontros_de(outra_pessoa)
    relacoes = self.relacoes_pessoa_grupo.where(eh_coordenador: true).select{|r| r.grupo.tem_encontros}

    relacoes.each do |relacao|
      if relacao.grupo.pessoas.include? outra_pessoa
        return true
      end
    end

    return false
  end

  def eh_coordenador_de_encontro_de(outra_pessoa)
    relacoes = self.relacoes_pessoa_conjunto.joins(:conjunto_pessoas).where("conjuntos_pessoas.tipo = 'CoordenacaoEncontro'")

    relacoes.each do |relacao|
      relacao.conjunto_pessoas.encontro.conjuntos.each do |conjunto|
        if conjunto.pessoas.include? outra_pessoa
          return true
        end
      end
    end

    return false
  end

  def eh_coordenador_de_conjunto_permanente_de(outra_pessoa)
    relacoes = self.relacoes_pessoa_conjunto.joins(:conjunto_pessoas).where('relacoes_pessoa_conjunto.eh_coordenador = true AND conjuntos_pessoas.tipo = "ConjuntoPermanente"')

    relacoes.each do |relacao|
      if relacao.conjunto_pessoas.pessoas.include? outra_pessoa
        return true
      end
    end

    return false
  end

  def grupos_que_coordena
    return self.relacoes_pessoa_grupo.where(eh_coordenador: true).collect{|r| r.grupo}
  end

  def grupos_que_tem_encontros_que_coordena
    return self.relacoes_pessoa_grupo.joins(:grupo).where('relacoes_pessoa_grupo.eh_coordenador = true AND grupos.tem_encontros = true').collect{|r| r.grupo}
  end

  def equipes_em_que_esta_participando_agora
    equipes = []
    self.equipes.each do |equipe|
      if equipe.encontro.data_liberacao.present? && equipe.encontro.data_fechamento.present?
        if (equipe.encontro.data_liberacao.beginning_of_day..equipe.encontro.data_fechamento.end_of_day).cover?(Time.now)
          equipes << equipe
        end
      end
    end

    return equipes
  end

  def encontros_que_esta_coordenando_agora
    encontros = []

    relacoes = self.relacoes_pessoa_conjunto.joins(:conjunto_pessoas).where("conjuntos_pessoas.tipo = 'CoordenacaoEncontro'")

    relacoes.each do |relacao|
      encontro = relacao.conjunto_pessoas.encontro

      if encontro.data_liberacao.present? && encontro.data_fechamento.present?
        if (encontro.data_liberacao.beginning_of_day..encontro.data_fechamento.end_of_day).cover?(Time.now)
          encontros << encontro
        end
      end
    end

    return encontros
  end

  def eh_coordenador_de_todos_os_grupos_de outra_pessoa
    grupos_que_coordena = self.grupos_que_coordena
    return outra_pessoa.grupos.count > 0 && (outra_pessoa.grupos - grupos_que_coordena).empty?
  end

  def grupos_em_que_pode_adicionar_outra_pessoa outra_pessoa
    if self.eh_super_admin?
      grupos = Grupo.all
    else
      grupos = self.grupos_que_coordena
    end

    return grupos - outra_pessoa.grupos
  end

  def participacoes

  end

  def endereco
    elementos = []
    elementos << "Rua #{self.rua}" unless self.rua.blank?
    elementos << "n. #{self.numero}" unless self.numero.blank?
    elementos << "Bairro #{self.bairro}" unless self.bairro.blank?
    elementos << self.cidade_com_estado unless self.cidade_com_estado.blank?
    elementos << "CEP #{self.cep}" unless self.cep.blank?

    return elementos.join(", ")
  end

  def cidade_com_estado
    elementos = []
    elementos << self.cidade unless self.cidade.blank?
    elementos << self.estado unless self.estado.blank?
    return elementos.join(" - ")
  end

  def validate_nascimento
    if !self.ano.blank? || !self.mes.blank? || !self.dia.blank?
      begin
        Date.parse("#{self.ano}-#{self.mes}-#{self.dia}")
      rescue
        errors.add(:nascimento, "Data inválida")
      end
    end
  end

  def validate_facebook
    if self.tem_facebook.present? && (self.tem_facebook == "on")
      if self.nome_facebook.blank?
        errors.add(:nome_facebook, "Obrigatório para quem tem Facebook")
      end

      if self.url_facebook.blank?
        errors.add(:url_facebook, "Obrigatório para quem tem Facebook")
      elsif self.new_record? && !Pessoa.where(:url_facebook => self.url_facebook).empty?
        errors.add(:url_facebook, "Já há outra pessoa com esse Facebook")
      end

      if self.url_foto_grande.blank?
        errors.add(:url_foto_grande, "Obrigatório para quem tem Facebook")
      end
    end
  end

  def validate_email
    if !self.email.blank? && ((self.email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i) == nil)
      errors.add(:email, "Email inválido")
    end
  end

  def validate_cep
    if !self.cep.blank? && ((self.cep =~ /[0-9]{5}-[0-9]{3}/) == nil)
      errors.add(:cep, "CEP inválido")
    end
  end

  private

  def default_values
    self.eh_homem = true if self.eh_homem.nil?
    self.eh_super_admin = false if self.eh_super_admin.nil?

    if !self.nascimento.blank? && (self.ano.blank? && self.mes.blank? && self.dia.blank?)
      self.ano = self.nascimento.year
      self.mes = self.nascimento.month
      self.dia = self.nascimento.day
    end
  end

  def atualizar_data
    if self.dia.present? && self.mes.present? && self.ano.present?
      begin
        self.nascimento = Date.parse("#{self.ano}-#{self.mes}-#{self.dia}")
      rescue
      end
    elsif self.nascimento.present?
      self.nascimento = nil
    end
  end

end