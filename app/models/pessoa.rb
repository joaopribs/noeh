#encoding: utf-8
require "open-uri"

class Pessoa < ActiveRecord::Base

  after_initialize :default_values

  before_save :atualizar_data
  after_create :atualizar_quem_criou
  after_save :atualizar_quem_editou

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
      string_pra_ordenar = "case pessoas.id"
      (0..array_ids.count - 1).each do |i|
        string_pra_ordenar += " when #{array_ids[i]} then #{i}"
      end
      string_pra_ordenar += " end"

      pessoas_do_banco = Pessoa.unscoped.where("pessoas.id IN (#{array_ids.join(", ")})").eager_load(:telefones).order(string_pra_ordenar)
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
    return self.url_facebook.present? || self.usuario_facebook.present? || self.id_app_facebook.present?
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

      grupos_que_tem_encontros_que_coordena.each do |grupo_coordena|
        grupos << grupo_coordena
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
        if (equipe.encontro.data_liberacao.beginning_of_day..equipe.encontro.data_fechamento.end_of_day).cover?(Time.zone.now)
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
            if (encontro.data_liberacao.beginning_of_day..encontro.data_fechamento.end_of_day).cover?(Time.zone.now)
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
          if (encontro.data_liberacao.beginning_of_day..encontro.data_fechamento.end_of_day).cover?(Time.zone.now)
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

  def participacoes_em_grupos(tipo_participacoes)
    participacoes = []

    grupos_ativos = self.grupos
    grupos_inativos = self.relacoes_pessoa_grupo.unscoped.where("pessoa_id = #{self.id} AND deixou_de_participar_em IS NOT NULL").collect{|r| r.grupo}.uniq

    grupos_ativos_casal = []
    grupos_inativos_casal = []

    if self.conjuge.present? && tipo_participacoes != "individuais_e_casal"
      grupos_ativos_conjuge = self.conjuge.grupos
      grupos_inativos_conjuge = self.conjuge.relacoes_pessoa_grupo.unscoped.where("pessoa_id = #{self.conjuge.id} AND deixou_de_participar_em IS NOT NULL").collect{|r| r.grupo}.uniq

      grupos_ativos_casal = grupos_ativos.select{|g| grupos_ativos_conjuge.include?(g)}
      grupos_inativos_casal = grupos_inativos.select{|g| grupos_inativos_conjuge.include?(g)}
    end

    if tipo_participacoes == "so_individuais"
      grupos_ativos = grupos_ativos - grupos_ativos_casal
      grupos_inativos = grupos_inativos - grupos_inativos_casal
    elsif tipo_participacoes == "so_casal"
      grupos_ativos = grupos_ativos_casal
      grupos_inativos = grupos_inativos_casal
    end

    grupos_ativos.each do |grupo|
      participacoes << {
          grupo: grupo,
          ativo: true
      }
    end

    grupos_inativos.each do |grupo|
      if !self.grupos.include? grupo
        participacoes << {
            grupo: grupo,
            ativo: false
        }
      end
    end

    return participacoes
  end

  def participacoes_visiveis(usuario_logado, tipo_participacoes)
    participacoes = (self.conjuntos_permanentes + self.equipes).select{|c| usuario_logado.permissoes.pode_ver_participacao(c, self)}
    participacoes = participacoes.sort_by!{|c| c.encontro.data_inicio}.reverse

    participacoes_de_casal = []

    if self.conjuge.present? && tipo_participacoes != "individuais_e_casal"
      participacoes_conjuge = (self.conjuge.conjuntos_permanentes + self.conjuge.equipes).select{|c| usuario_logado.permissoes.pode_ver_participacao(c, self.conjuge)}
      participacoes_de_casal = participacoes.select{|c| participacoes_conjuge.include?(c)}
    end

    if tipo_participacoes == "so_individuais"
      participacoes = participacoes - participacoes_de_casal
    elsif tipo_participacoes == "so_casal"
      participacoes = participacoes_de_casal
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
      if self.url_facebook.blank?
        errors.add(:url_facebook, "Obrigatório para quem tem Facebook")
      else 
        pessoas = Pessoa.where(:url_facebook => self.url_facebook)
        if (pessoas.count == 1 && pessoas.first != self) || pessoas.count > 1
          errors.add(:url_facebook, "Já há outra pessoa com esse Facebook")
        end
      end

      if !self.usuario_facebook.blank?
        pessoas = Pessoa.where(:usuario_facebook => self.usuario_facebook)
        if (pessoas.count == 1 && pessoas.first != self) || pessoas.count > 1
          errors.add(:url_facebook, "Já há outra pessoa com esse Facebook")
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
    if !self.cep.blank? && ((self.cep =~ /[0-9]{2}.[0-9]{3}-[0-9]{3}/) == nil)
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

  def atualizar_quem_criou
    if self.quem_criou.nil?
      self.quem_criou = self.id
      self.save
    end
  end

  def atualizar_quem_editou
    if self.quem_editou.nil?
      self.quem_editou = self.id
      self.save
    end
  end

end