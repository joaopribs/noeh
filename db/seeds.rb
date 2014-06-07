#encoding: utf-8

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
criar_cor("Lilás", "#C8A2C8", "#fff", false, true)

(Cor.all - @@cores).each { |cor| cor.destroy }

joao = Pessoa.find_by_url_facebook('https://www.facebook.com/joaopaulo.ribs')
if joao.nil?
  joao = Pessoa.new({
      nome: 'João Paulo Ribeiro da Silva',
      nome_usual: 'João',
      nome_facebook: 'João Paulo Ribeiro',
      url_facebook: 'https://www.facebook.com/joaopaulo.ribs',
      url_foto_grande: 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-xpa1/t1.0-1/c0.0.320.320/p320x320/1238716_803437719668628_1377999441330663131_n.jpg',
      eh_super_admin: true
  })

  joao.save
end