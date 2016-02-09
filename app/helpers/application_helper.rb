#encoding: utf-8

module ApplicationHelper

  def estados_brasil
    return ['AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR', 'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO']
  end

  def operadoras_telefone
    return ['Fixo', 'Claro', 'Nextel', 'Oi', 'Tim', 'Vivo']
  end

  def instrumentos
    return ['Vocal', 'Baixo', 'Bateria', 'Guitarra', 'Percussão', 'Sanfona', 'Saxofone', 'Teclado', 'Violão']
  end

  def relacionamentos
    return {
      masculino: ['Afilhado', 'Avô', 'Cunhado', 'Ex-Marido', 'Ex-Namorado', 'Filho', 'Genro', 'Irmão', 'Namorado', 'Neto', 'Padrasto', 'Pai', 'Primo', 'Sobrinho', 'Sogro', 'Tio'], 
      feminino: ['Afilhada', 'Avó', 'Cunhada', 'Ex-Esposa', 'Ex-Namorada', 'Filha', 'Irmã', 'Madrasta', 'Mãe', 'Namorada', 'Neta', 'Nora', 'Prima', 'Sobrinha', 'Sogra', 'Tia']
    }
  end

  def denominacoes_conjuntos_permanentes
    return [
      {
        nome: "Círculo",
        plural: "Círculos"
      },
      {
        nome: "Grupo",
        plural: "Grupos"
      }
    ]
  end

  def cores_equipes
    return [
        ["Sem cor" ,""],
        "Vermelho", "Amarelo", "Verde"]
  end

  def cores_conjuntos_permanentes
    return [
        ["Sem cor" ,""],
        "Amarelo", "Azul", "Branco", "Laranja", "Marrom", "Preto", "Rosa", "Roxo", "Verde", "Vermelho", "Violeta"]
  end

  def formatar_data(data)
    begin
      return data.strftime("%d/%m/%Y")
    rescue
      return data
    end
  end

  def render_breadcrumbs(identificador_ativo)
    render partial: 'shared/breadcrumbs', locals: { ativo: identificador_ativo }
  end

  def helper_whatsapp(telefone)
    if telefone.eh_whatsapp
      return '<span class="whatsapp">WhatsApp</span> '
    else
      return ''
    end
  end

end
