class Equipe < ConjuntoPessoas
  has_attached_file :relatorio,
                    :default_url => "",
                    :storage => :dropbox,
                    :dropbox_credentials => Rails.root.join("config/dropbox_privado.yml"),
                    :dropbox_visibility => 'private',
                    :path => "relatorio/:filename"

  belongs_to :equipe_padrao_relacionada, class_name: 'Equipe', foreign_key: 'equipe_padrao_relacionada'
  has_many :equipes_para_a_qual_eh_padrao, class_name: 'Equipe', foreign_key: 'equipe_padrao_relacionada', dependent: :nullify

  validates_attachment_content_type :relatorio, :content_type => ["application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/pdf"]

  def tipo_de_arquivo
    if self.relatorio_content_type == "application/pdf"
      return "pdf"
    elsif ["application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"].include?(self.relatorio_content_type)
      return "word"
    end
  end

  def nome_pra_auto_sugestao
    return "#{self.tipo_do_conjunto} #{self.nome}"
  end

  def nome
    if self.equipe_padrao_relacionada.present?
      return self.equipe_padrao_relacionada.read_attribute(:nome)
    else
      return self.read_attribute(:nome)
    end
  end
end
