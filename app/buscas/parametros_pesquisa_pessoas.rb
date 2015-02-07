class ParametrosPesquisaPessoas

  attr_accessor :submeteu, :nome, :generos, :estados_civis, :instrumentos, :grupos, :equipes, :recomendacoes

  def initialize
    self.submeteu = false
    self.generos = []
    self.estados_civis = []
    self.instrumentos = []
    self.grupos = []
    self.equipes = []
    self.recomendacoes = []
  end

end