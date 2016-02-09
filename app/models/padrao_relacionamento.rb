#encoding: utf-8

class PadraoRelacionamento < ActiveRecord::Base

  self.table_name = :padroes_relacionamento

  belongs_to :relacionamento_oposto, class_name: 'PadraoRelacionamento', foreign_key: 'relacionamento_oposto_id', dependent: :destroy

end
