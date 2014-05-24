module Auditavel
  extend ActiveSupport::Concern

  included do
    before_create :atualizar_quem_criou
    before_update :atualizar_quem_editou
    before_destroy {
      self.update_column(:quando_deletou, Time.now)
      if self.usuario_corrente.present?
        self.update_column(:quem_deletou_id, self.usuario_corrente.id)
      end
    }

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
    run_callbacks :destroy do
      # Isso eh pra previnir os callbacks depois de excluir
    end
  end

end