#encoding: utf-8

module ApplicationHelper

  def pode_criar_pessoa_em_um_grupo grupo
    return @usuario_logado.eh_super_admin? ||
        grupo.coordenadores.include?(@usuario_logado)
  end

  def pode_editar_facebook_de_pessoa pessoa_a_ser_editada
    if @usuario_logado.id == pessoa_a_ser_editada.id
      return false
    end

    if @usuario_logado.eh_super_admin
      return true
    elsif @usuario_logado.eh_coordenador_de_grupo_de(pessoa_a_ser_editada)
      return true
    elsif pessoa_a_ser_editada.new_record?
      return true
    end

    return false
  end

  def pode_remover_facebook pessoa_a_ser_editada
    if (@usuario_logado.eh_super_admin && @usuario_logado.id != pessoa_a_ser_editada.id) ||
        ((@usuario_logado.eh_coordenador_de_grupo_que_tem_encontros_de(pessoa_a_ser_editada) || @usuario_logado.eh_coordenador_de_todos_os_grupos_de(pessoa_a_ser_editada)) &&
            @usuario_logado.id != pessoa_a_ser_editada.id)
      return true
    end

    return false
  end

  def pode_excluir_pessoa pessoa_a_ser_excluida
    if @usuario_logado.eh_super_admin ||
        ((@usuario_logado.eh_coordenador_de_grupo_que_tem_encontros_de(pessoa_a_ser_excluida) || @usuario_logado.eh_coordenador_de_todos_os_grupos_de(pessoa_a_ser_excluida)) &&
            @usuario_logado.id != pessoa_a_ser_excluida.id && !pessoa_a_ser_excluida.eh_super_admin?)
      return true
    end

    return false
  end

  def pode_editar_pessoa pessoa_a_ser_editada
    if @usuario_logado.eh_super_admin ||
        @usuario_logado.id == pessoa_a_ser_editada.id ||
        (@usuario_logado.eh_coordenador_de_grupo_que_tem_encontros_de(pessoa_a_ser_editada) || @usuario_logado.eh_coordenador_de_todos_os_grupos_de(pessoa_a_ser_editada))
      return true
    end

    return false
  end

  def pode_alterar_estado_civil_de outra_pessoa
    if @usuario_logado.eh_super_admin ||
        outra_pessoa.new_record? ||
        (@usuario_logado.eh_coordenador_de_grupo_que_tem_encontros_de(outra_pessoa) || @usuario_logado.eh_coordenador_de_todos_os_grupos_de(outra_pessoa))
      return true
    end

    return false
  end

  def pode_alterar_tipo_de_conjuge pessoa
    if @usuario_logado.eh_super_admin ||
        pessoa.new_record? ||
        ((@usuario_logado.eh_coordenador_de_grupo_que_tem_encontros_de(pessoa) || @usuario_logado.eh_coordenador_de_todos_os_grupos_de(pessoa)) &&
            ((pessoa.conjuge.blank?) || (@usuario_logado.eh_coordenador_de_grupo_que_tem_encontros_de(pessoa.conjuge) || @usuario_logado.eh_coordenador_de_todos_os_grupos_de(pessoa.conjuge))))
      return true
    end

    return false
  end

  def pode_editar_conjunto conjunto
    return @usuario_logado.eh_super_admin ||
        conjunto.encontro.grupo.coordenadores.include?(@usuario_logado) ||
        conjunto.encontro.coordenadores.include?(@usuario_logado)
  end

  def pode_criar_encontro_no_grupo grupo
    return @usuario_logado.eh_super_admin? || grupo.coordenadores.include?(@usuario_logado)
  end

  def pode_excluir_encontro encontro
    return @usuario_logado.eh_super_admin? || encontro.grupo.coordenadores.include?(@usuario_logado)
  end

  def pode_editar_coordenador_de_conjunto conjunto
    return @usuario_logado.eh_super_admin? ||
        conjunto.encontro.coordenadores.include?(@usuario_logado) ||
        conjunto.encontro.grupo.coordenadores.include?(@usuario_logado)
  end

  def pode_gerenciar_grupo grupo
    return @usuario_logado.eh_super_admin? || grupo.coordenadores.include?(@usuario_logado)
  end

  def pode_ver_encontro encontro
    return @usuario_logado.eh_super_admin? || encontro.coordenadores.include?(@usuario_logado) || encontro.grupo.coordenadores.include?(@usuario_logado)
  end

  def estados_brasil
    return ['AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR', 'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO']
  end

  def operadoras_telefone
    return ['Fixo', 'Claro', 'Nextel', 'Oi', 'Tim', 'Vivo']
  end

  def instrumentos
    return ['Canto', 'Baixo', 'Bateria', 'Guitarra', 'Percussão', 'Sanfona', 'Saxofone', 'Teclado', 'Violão']
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

end
