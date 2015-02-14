#encoding: utf-8

class AutoSugestao < ActiveRecord::Base

  belongs_to :pessoa
  belongs_to :grupo
  belongs_to :encontro
  belongs_to :conjuge, class_name: 'Pessoa', foreign_key: :conjuge_id

  self.table_name = "auto_sugestao"

end