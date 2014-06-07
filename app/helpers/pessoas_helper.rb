#encoding: utf-8

module PessoasHelper

  def pessoa_participando_de_outro_conjunto_em_encontro(pessoa, conjunto)
    html = ''

    encontro = conjunto.encontro

    equipes = pessoa.equipes.select{|equipe| equipe != conjunto && equipe.encontro == encontro}
    conjuntos_permanentes = pessoa.conjuntos_permanentes.select{|conjunto_permanente| conjunto_permanente != conjunto && conjunto_permanente.encontro == encontro}

    if equipes.count + conjuntos_permanentes.count > 0
      html = '<br/><em>Também participa de '

      texto_tudo_array = []

      if equipes.count > 0
        if equipes.count == 1
          texto_equipes = 'Equipe: '
        else
          texto_equipes = 'Equipes: '
        end

        texto_equipes_array = []
        equipes.each do |equipe|
          texto_equipes_array << equipe.nome
        end

        texto_equipes += texto_equipes_array.join(", ")

        texto_tudo_array << texto_equipes
      end

      if conjuntos_permanentes.count > 0
        if conjuntos_permanentes.count == 1
          texto_conjuntos_permanentes = encontro.denominacao_conjuntos_permanentes
        else
          texto_conjuntos_permanentes = denominacoes_conjuntos_permanentes.select{|d| d.nome == encontro.denominacao_conjuntos_permanentes}[0][:plural]
        end

        texto_conjuntos_permanentes += ': '

        texto_conjuntos_permanentes_array = []
        conjuntos_permanentes.each do |conjunto_permanente|
          texto_conjuntos_permanentes_array << conjunto_permanente.nome
        end

        texto_conjuntos_permanentes += texto_conjuntos_permanentes_array.join(", ")

        texto_tudo_array << texto_conjuntos_permanentes
      end

      html += texto_tudo_array.join("; ")

      html += '</em>'
    end

    return raw html
  end

end