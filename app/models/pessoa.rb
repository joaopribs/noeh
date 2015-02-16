#encoding: utf-8
require "open-uri"

class Pessoa < ActiveRecord::Base

  after_initialize :default_values

  before_save :atualizar_data

  default_scope {where('pessoas.auto_inserido IS NULL OR pessoas.auto_inserido = false')}
  default_scope {order(:nome)}

  attr_accessor :dia, :mes, :ano, :tem_facebook

  has_many :relacoes_pessoa_conjunto, class_name: 'RelacaoPessoaConjunto', dependent: :destroy
  has_many :conjuntos_pessoas, through: :relacoes_pessoa_conjunto, source: 'conjunto_pessoas'
  has_many :equipes, -> { where tipo: ['Equipe', 'CoordenacaoEncontro'] }, through: :relacoes_pessoa_conjunto, source: 'conjunto_pessoas'
  has_many :conjuntos_permanentes, -> { where tipo: 'ConjuntoPermanente' }, through: :relacoes_pessoa_conjunto, source: 'conjunto_pessoas'
  has_many :relacoes_pessoa_grupo, class_name: 'RelacaoPessoaGrupo', dependent: :destroy
  has_many :grupos, -> { where 'relacoes_pessoa_grupo.deixou_de_participar_em IS NULL' }, through: :relacoes_pessoa_grupo
  has_many :telefones, dependent: :destroy
  has_many :instrumentos, dependent: :destroy
  has_many :auto_sugestoes, class_name: 'AutoSugestao', dependent: :destroy
  has_many :recomendacoes_equipes, -> {order(:posicao)}, class_name: 'RecomendacaoEquipe', dependent: :destroy

  has_one :recomendacao_do_coordenador_permanente, dependent: :destroy

  belongs_to :conjuge, class_name: 'Pessoa', foreign_key: :conjuge_id, dependent: :destroy

  validates :nome, :presence => {:message => "Obrigatório"}
  validates :nome_usual, :presence => {:message => "Obrigatório"}
  validates :eh_homem, :inclusion => {:in => [true, false], :message => "Obrigatório"}
  validates :eh_super_admin, :inclusion => {:in => [true, false]}

  validate :validate_nascimento
  validate :validate_facebook
  validate :validate_email
  validate :validate_cep

  has_attached_file :foto_grande,
    :default_url => "",
    :storage => :dropbox, 
    :dropbox_credentials => Rails.root.join("config/dropbox_publico.yml"),
    :dropbox_visibility => 'public',
    :path => "foto_grande/:filename"

  has_attached_file :foto_pequena,
    :default_url => "",
    :storage => :dropbox, 
    :dropbox_credentials => Rails.root.join("config/dropbox_publico.yml"),
    :dropbox_visibility => 'public',
    :path => "foto_pequena/:filename"

  validates_attachment_content_type :foto_grande, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]
  validates_attachment_content_type :foto_pequena, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]

  # def conjuge
  #   Pessoa.unscoped{ super }
  # end

  def permissoes
    @permissoes = Permissoes.new(self)
    return @permissoes
  end

  def self.pegar_pessoas array_ids, forcar_conjuges
    pessoas = []

    if array_ids.present? && array_ids.count > 0
      pessoas_do_banco = Pessoa.unscoped.where("pessoas.id IN (#{array_ids.join(", ")})").eager_load(:telefones).order(:nome)
      pessoas = pessoas.concat(pessoas_do_banco.to_a);
    end

    if forcar_conjuges
      pessoas.map do |pessoa|
        if pessoa.conjuge_id.present?
          pessoa.conjuge = Pessoa.unscoped.find(pessoa.conjuge_id)
        end
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
    if self.foto_pequena.present? || self.foto_grande.present?
      if tamanho < 80
        url = self.foto_pequena.present? ? self.foto_pequena.url : self.foto_grande.url
      else
        url = self.foto_grande.present? ? self.foto_grande.url : self.foto_pequena.url
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
    if self.eh_super_admin
      return Grupo.all
    else
      return self.relacoes_pessoa_grupo.where(eh_coordenador: true).collect{|r| r.grupo}
    end
  end

  def grupos_que_tem_encontros_que_coordena
    if self.eh_super_admin
      return Grupo.where(tem_encontros: true)
    else
      return self.relacoes_pessoa_grupo.joins(:grupo).where('relacoes_pessoa_grupo.eh_coordenador = true AND grupos.tem_encontros = true').collect{|r| r.grupo}
    end
  end

  def grupos_que_nao_tem_encontros_que_coordena
    if self.eh_super_admin
      return Grupo.where(tem_encontros: false)
    else
      return self.relacoes_pessoa_grupo.joins(:grupo).where('relacoes_pessoa_grupo.eh_coordenador = true AND grupos.tem_encontros = false').collect{|r| r.grupo}
    end
  end

  def grupos_que_pode_ver
    if self.eh_super_admin
      return Grupo.all
    else
      grupos = []

      grupos_que_tem_encontros_que_coordena = self.grupos_que_tem_encontros_que_coordena

      if grupos_que_tem_encontros_que_coordena
        grupos = grupos_que_tem_encontros_que_coordena
      end

      grupos_que_tem_encontros_que_coordena.each do |grupo_coordena|
        grupo_coordena.outros_grupos_que_pode_ver_equipes.each do |outro_grupo|
          grupos << outro_grupo
        end
      end

      grupos.concat(Grupo.where(tem_encontros: false))

      if grupos.count > 0
        grupos = grupos.uniq.sort_by{|g| g.nome}
      end

      return grupos
    end
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

  def equipes_que_esta_coordenando_agora
    return equipes_em_que_esta_participando_agora.select{|e| e.coordenadores.include?(self)}
  end

  def esta_coordenando_agora_alguma_equipe_de_outra_pessoa outra_pessoa
    return equipes_que_esta_coordenando_agora.select{|e| e.pessoas.include?(outra_pessoa)}.count > 0
  end

  def encontros_que_esta_coordenando_agora
    encontros = []

    grupos_que_tem_encontros_que_coordena = self.grupos_que_tem_encontros_que_coordena

    if grupos_que_tem_encontros_que_coordena.count > 0
      grupos_que_tem_encontros_que_coordena.each do |grupo|
        grupo.encontros.each do |encontro|
          if encontro.data_liberacao.present? && encontro.data_fechamento.present?
            if (encontro.data_liberacao.beginning_of_day..encontro.data_fechamento.end_of_day).cover?(Time.now)
              encontros << encontro
            end
          end
        end
      end
    else
      relacoes = self.relacoes_pessoa_conjunto.joins(:conjunto_pessoas).where("conjuntos_pessoas.tipo = 'CoordenacaoEncontro'")

      relacoes.each do |relacao|
        encontro = relacao.conjunto_pessoas.encontro

        if encontro.data_liberacao.present? && encontro.data_fechamento.present?
          if (encontro.data_liberacao.beginning_of_day..encontro.data_fechamento.end_of_day).cover?(Time.now)
            encontros << encontro
          end
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
    grupos = self.grupos_que_coordena

    return grupos - outra_pessoa.grupos
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

  def participacoes_em_grupos
    participacoes = []

    self.grupos.each do |grupo|
      participacoes << {
          grupo: grupo,
          ativo: true
      }
    end

    self.relacoes_pessoa_grupo.unscoped.where("pessoa_id = #{self.id} AND deixou_de_participar_em IS NOT NULL").collect{|r| r.grupo}.uniq.each do |grupo|
      if !self.grupos.include? grupo
        participacoes << {
            grupo: grupo,
            ativo: false
        }
      end
    end

    return participacoes
  end

  def auto_sugestoes_ordenadas
    retorno = []

    auto_sugestoes = self.auto_sugestoes

    retorno = retorno.concat(auto_sugestoes.select{|a| a.encontro.nil?}.sort_by{|a| a.grupo.nome})
    retorno = retorno.concat(auto_sugestoes.select{|a| !a.encontro.nil?}.sort_by{|a| [a.grupo.nome, a.encontro.data_inicio.year]})

    return retorno
  end

  def quantas_auto_sugestoes_individuais_ou_casal
    if self.conjuge_id.present?
      return AutoSugestao.where("pessoa_id = #{self.id} OR conjuge_id = #{self.conjuge_id}").count
    else
      return AutoSugestao.where("pessoa_id = #{self.id}").count
    end
  end

  def ids_pessoas_a_confirmar
    retorno = []

    grupos = self.grupos_que_coordena

    grupos.each do |grupo|
      retorno = retorno.concat(grupo.ids_pessoas_a_confirmar)
    end

    return retorno.uniq
  end

  def pessoas_a_confirmar
    ids = self.ids_pessoas_a_confirmar

    pessoas = ids.collect{|id| Pessoa.unscoped.find(id)}.sort_by{|p| p.nome}

    return pessoas
  end

  def auto_sugestoes_de_outra_pessoa id_outra_pessoa
    auto_sugestoes = []

    grupos = self.grupos_que_coordena

    grupos.each do |grupo|
      auto_sugestoes = auto_sugestoes.concat(grupo.auto_sugestoes_individuais_de_pessoa(id_outra_pessoa))
    end

    auto_sugestoes_ordenado = []

    auto_sugestoes_ordenado = auto_sugestoes_ordenado.concat(auto_sugestoes.select{|a| a.encontro.nil?}.sort_by{|a| a.grupo.nome})
    auto_sugestoes_ordenado = auto_sugestoes_ordenado.concat(auto_sugestoes.select{|a| !a.encontro.nil?}.sort_by{|a| [a.grupo.nome, a.encontro.data_inicio.year]})

    return auto_sugestoes_ordenado
  end

  def auto_sugestoes_de_casal id_outra_pessoa
    auto_sugestoes = []

    grupos = self.grupos_que_coordena

    grupos.each do |grupo|
      auto_sugestoes = auto_sugestoes.concat(grupo.auto_sugestoes_de_casal(id_outra_pessoa))
    end

    auto_sugestoes_ordenado = []

    auto_sugestoes_ordenado = auto_sugestoes_ordenado.concat(auto_sugestoes.select{|a| a.encontro.nil?}.sort_by{|a| a.grupo.nome})
    auto_sugestoes_ordenado = auto_sugestoes_ordenado.concat(auto_sugestoes.select{|a| !a.encontro.nil?}.sort_by{|a| [a.grupo.nome, a.encontro.data_inicio.year]})

    return auto_sugestoes_ordenado
  end

  def eh_coordenador_de_algum_grupo_que_tem_encontros
    return self.grupos_que_coordena.select{|g| g.tem_encontros}.count > 0
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

      if self.url_imagem_facebook.blank?
        errors.add(:url_imagem_facebook, "Obrigatório para quem tem Facebook")
      else
        begin
          open(self.url_imagem_facebook)
        rescue OpenURI::HTTPError
          errors.add(:url_imagem_facebook, "A imagem não pôde ser carregada")
        end
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
    self.auto_inserido = false if self.auto_inserido.nil?

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