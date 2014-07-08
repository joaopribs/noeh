#encoding: utf-8

class AutoSugestao < ActiveRecord::Base

  belongs_to :pessoa
  belongs_to :grupo
  belongs_to :encontro

  self.table_name = "auto_sugestao"

end