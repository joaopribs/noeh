#encoding: utf-8

class RelacaoPessoaConjunto < ActiveRecord::Base

  after_initialize :default_values

  self.table_name = "relacoes_pessoa_conjunto"

  belongs_to :pessoa
  belongs_to :conjunto_pessoas

  validates :eh_coordenador, :inclusion => {:in => [true, false], :message => "É obrigatório dizer se é coordenador"}

  private

  def default_values
    self.eh_coordenador = false if self.eh_coordenador.nil?
  end

end