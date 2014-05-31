#encoding: utf-8

class RelacaoPessoaGrupo < ActiveRecord::Base

  self.table_name = "relacoes_pessoa_grupo"

  default_scope { where({deixou_de_participar_em: nil}) }

  after_initialize :default_values

  belongs_to :pessoa
  belongs_to :grupo

  validates :eh_coordenador, :inclusion => {:in => [true, false], :message => "É obrigatório dizer se é coordenador"}

  private

  def default_values
    self.eh_coordenador = false if self.eh_coordenador.nil?
  end

end
