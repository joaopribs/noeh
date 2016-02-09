#encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

@cores = []

def self.criar_cor(nome, hex_cor, hex_cor_hover, hex_contraste, de_equipe, de_conjunto_permanente, classe_css)
  cor = Cor.where(nome: nome).first

  if cor
    cor.hex_cor = hex_cor
    cor.hex_cor_hover = hex_cor_hover
    cor.hex_contraste = hex_contraste
    cor.de_equipe = de_equipe
    cor.de_conjunto_permanente = de_conjunto_permanente
    cor.classe_css = classe_css
  else
    cor = Cor.new({
                      nome: nome,
                      hex_cor: hex_cor,
                      hex_cor_hover: hex_cor_hover,
                      hex_contraste: hex_contraste,
                      de_equipe: de_equipe,
                      de_conjunto_permanente: de_conjunto_permanente,
                      classe_css: classe_css})
  end

  cor.save

  @cores << cor
end

criar_cor("Amarelo", "#e3c800", "#ffe100", "#000", true, true, "link_amarelo_dinamico")
criar_cor("Azul", "#004be3", "#0054ff", "#fff", false, true, "link_azul_dinamico")
criar_cor("Branco", "#fff", "#d0d0d0", "#000", false, true, "link_branco_dinamico")
criar_cor("Laranja", "#f86f05", "#ff9340", "#fff", false, true, "link_laranja_dinamico")
criar_cor("Marrom", "#6d4323", "#a1602f", "#fff", false, true, "link_marrom_dinamico")
criar_cor("Preto", "#000", "#494949", "#fff", false, true, "link_preto_dinamico")
criar_cor("Rosa", "#ff6ebc", "#cd2b82", "#fff", false, true, "link_rosa_dinamico")
criar_cor("Roxo", "#8309eb", "#5c02a8", "#fff", false, true, "link_roxo_dinamico")
criar_cor("Verde", "#39a233", "#63df5c", "#fff", true, true, "link_verde_dinamico")
criar_cor("Vermelho", "#df0e0e", "#ff6b6b", "#fff", true, true, "link_vermelho_dinamico")
criar_cor("Violeta", "#c572c5", "#a566a5", "#fff", false, true, "link_violeta_dinamico")
criar_cor("Lilás", "#C8A2C8", "#b590b5", "#fff", false, true, "link_lilas_dinamico")

(Cor.all - @cores).each { |cor| cor.destroy }

joao = Pessoa.find_by_url_facebook('https://www.facebook.com/joaopaulo.ribs')
if joao.nil?
  joao = Pessoa.new({
      nome: 'João Paulo Ribeiro da Silva',
      nome_usual: 'João',
      url_facebook: 'https://www.facebook.com/joaopaulo.ribs',
      usuario_facebook: 'joaopaulo.ribs',
      eh_super_admin: true
  })

  joao.save
end

@padroes_relacionamento = []

def self.criar_padrao_relacionamento(relacionamento_masculino, relacionamento_feminino)
  padrao_relacionamento = PadraoRelacionamento.where(relacionamento_masculino: relacionamento_masculino).first

  if padrao_relacionamento
    padrao_relacionamento.relacionamento_masculino = relacionamento_masculino
    padrao_relacionamento.relacionamento_feminino = relacionamento_feminino
  else
    padrao_relacionamento = PadraoRelacionamento.new(
      {
        relacionamento_masculino: relacionamento_masculino, 
        relacionamento_feminino: relacionamento_feminino
      })
  end

  padrao_relacionamento.save

  @padroes_relacionamento << padrao_relacionamento
end

criar_padrao_relacionamento('Afilhado', 'Afilhada')
criar_padrao_relacionamento('Avô', 'Avó')
criar_padrao_relacionamento('Cunhado', 'Cunhada')
criar_padrao_relacionamento('Enteado', 'Enteada')
criar_padrao_relacionamento('Filho', 'Filha')
criar_padrao_relacionamento('Genro', 'Nora')
criar_padrao_relacionamento('Irmão', 'Irmã')
criar_padrao_relacionamento('Namorado', 'Namorada')
criar_padrao_relacionamento('Neto', 'Neta')
criar_padrao_relacionamento('Padrasto', 'Madrasta')
criar_padrao_relacionamento('Padrinho', 'Madrinha')
criar_padrao_relacionamento('Pai', 'Mãe')
criar_padrao_relacionamento('Primo', 'Prima')
criar_padrao_relacionamento('Sobrinho', 'Sobrinha')
criar_padrao_relacionamento('Sogro', 'Sogra')
criar_padrao_relacionamento('Tio', 'Tia')

(PadraoRelacionamento.all - @padroes_relacionamento).each { |padrao_relacionamento| padrao_relacionamento.destroy }

def self.setar_relacionamento_oposto(relacionamento_masculino, relacionamento_oposto)
  padrao1 = PadraoRelacionamento.where(relacionamento_masculino: relacionamento_masculino).first
  padrao2 = PadraoRelacionamento.where(relacionamento_masculino: relacionamento_oposto).first

  if padrao1 && padrao2
    if padrao1.relacionamento_oposto != padrao2
      padrao1.relacionamento_oposto = padrao2
      padrao1.save
    end

    if padrao2.relacionamento_oposto != padrao1
      padrao2.relacionamento_oposto = padrao1
      padrao2.save
    end
  end
end

setar_relacionamento_oposto('Afilhado', 'Padrinho')
setar_relacionamento_oposto('Avô', 'Neto')
setar_relacionamento_oposto('Cunhado', 'Cunhado')
setar_relacionamento_oposto('Enteado', 'Padrasto')
setar_relacionamento_oposto('Filho', 'Pai')
setar_relacionamento_oposto('Genro', 'Sogro')
setar_relacionamento_oposto('Irmão', 'Irmão')
setar_relacionamento_oposto('Namorado', 'Namorado')
setar_relacionamento_oposto('Primo', 'Primo')
setar_relacionamento_oposto('Sobrinho', 'Tio')