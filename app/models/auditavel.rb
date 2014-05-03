module Auditavel
  extend ActiveSupport::Concern

  included do
    before_create :atualizar_quem_criou
    before_update :atualizar_quem_editou

    default_scope { where(quando_deletou: nil) }

    attr_accessor :usuario_corrente

    has_one :quem_criou, class_name: 'Pessoa', foreign_key: :quem_criou_id
    has_one :quem_editou, class_name: 'Pessoa', foreign_key: :quem_editou_id
    has_one :quem_deletou, class_name: 'Pessoa', foreign_key: :quem_deletou_id
  end

  def atualizar_quem_criou
    if self.usuario_corrente.present?
      self.quem_criou_id = self.usuario_corrente.id
    end
  end

  def atualizar_quem_editou
    if self.usuario_corrente.present?
      self.quem_editou_id = self.usuario_corrente.id
    end
  end

  def destroy
    # esse update_column eh pra nao rodar o callback before_update (nao quero que
    # marque "quem_editou" quando fizer uma exclusao)

    self.update_column(:quando_deletou, Time.now)
    if self.usuario_corrente.present?
      self.update_column(:quem_deletou_id, self.usuario_corrente.id)
    end

    if defined?(self.conjuge) && self.conjuge.present?
      self.conjuge.update_column(:quando_deletou, Time.now)
      if self.usuario_corrente.present?
        self.conjuge.update_column(:quem_deletou_id, self.usuario_corrente.id)
      end
    end

  end

end