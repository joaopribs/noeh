# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

@@cores = []

def self.criar_cor(nome, hex_cor, hex_contraste, de_equipe, de_conjunto_permanente)
  cor = Cor.where(nome: nome).first

  if cor
    cor.hex_cor = hex_cor
    cor.hex_contraste = hex_contraste
    cor.de_equipe = de_equipe
    cor.de_conjunto_permanente = de_conjunto_permanente
  else
    cor = Cor.new({
                      nome: nome,
                      hex_cor: hex_cor,
                      hex_contraste: hex_contraste,
                      de_equipe: de_equipe,
                      de_conjunto_permanente: de_conjunto_permanente})
  end

  cor.save

  @@cores << cor
end

criar_cor("Amarelo", "#e3c800", "#000", true, true)
criar_cor("Azul", "#004be3", "#fff", false, true)
criar_cor("Branco", "#fff", "#000", false, true)
criar_cor("Laranja", "#f86f05", "#fff", false, true)
criar_cor("Marrom", "#6d4323", "#fff", false, true)
criar_cor("Preto", "#000", "#fff", false, true)
criar_cor("Rosa", "#ff6ebc", "#fff", false, true)
criar_cor("Roxo", "#8309eb", "#fff", false, true)
criar_cor("Verde", "#39a233", "#fff", true, true)
criar_cor("Vermelho", "#df0e0e", "#fff", true, true)
criar_cor("Violeta", "#c572c5", "#fff", false, true)

(Cor.all - @@cores).each { |cor| cor.destroy }