#encoding: utf-8

class Pessoa < ActiveRecord::Base
  include Auditavel
  after_initialize :default_values
  before_save :atualizar_data
  default_scope { order(:nome) }

  attr_accessor :dia, :mes, :ano

  has_many :relacoes_pessoa_grupo, class_name: 'RelacaoPessoaGrupo', dependent: :destroy
  has_many :grupos, through: :relacoes_pessoa_grupo

  belongs_to :conjuge, class_name: 'Pessoa', foreign_key: :conjuge_id, dependent: :delete

  validates :nome, :presence => {:message => "Obrigatório"}
  validates :nome_usual, :presence => {:message => "Obrigatório"}
  validates :eh_homem, :inclusion => {:in => [true, false], :message => "Obrigatório"}
  validates :eh_super_admin, :inclusion => {:in => [true, false]}

  validate :validate_nascimento
  validate :validate_facebook
  validate :validate_email
  validate :validate_cep

  def url_imagem square, largura, altura
    if self.id_facebook.present?
      url = []
      url << "http://graph.facebook.com/#{self.id_facebook}/picture?"

      params = []
      if square
        params << "type=square"
      end
      params << "width=#{largura}" unless largura.nil?
      params << "height=#{altura}" unless altura.nil?

      url << params.join("&")
      url = url.join
    else
      if largura > 120
        url = "/assets/semfoto200.png"
      elsif largura > 80
        url = "/assets/semfoto100.png"
      else
        url = "/assets/semfoto50.png"
      end
    end

    return url
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
    if self.new_record? && self.id_facebook.present? && !Pessoa.where(:id_facebook => self.id_facebook).empty?
      errors.add(:id_facebook, "Já há outra pessoa com esse Facebook")
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

  def eh_coordenador_de_grupo_de(outra_pessoa)
    relacoes = self.relacoes_pessoa_grupo.where(eh_coordenador: true)

    relacoes.each do |relacao|
      if relacao.grupo.pessoas.include? outra_pessoa
        return true
      end
    end

    return false
  end

  def eh_coordenador_de_super_grupo_de(outra_pessoa)
    relacoes = self.relacoes_pessoa_grupo.where(eh_coordenador: true).select{|r| r.grupo.eh_super_grupo}

    relacoes.each do |relacao|
      if relacao.grupo.pessoas.include? outra_pessoa
        return true
      end
    end

    return false
  end

  def grupos_que_coordena
    return self.relacoes_pessoa_grupo.where(eh_coordenador: true).collect{|r| r.grupo}
  end

  def eh_coordenador_de_todos_os_grupos_de outra_pessoa
    grupos_que_coordena = self.grupos_que_coordena
    return outra_pessoa.grupos.count > 0 && (outra_pessoa.grupos - grupos_que_coordena).empty?
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