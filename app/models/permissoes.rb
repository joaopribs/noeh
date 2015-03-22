class Permissoes

	attr_accessor :usuario_logado

	def initialize(usuario_logado)
		@usuario_logado = usuario_logado
	end

	def pode_ver_pessoa pessoa
		return @usuario_logado.eh_super_admin? ||
		  @usuario_logado.eh_coordenador_de_grupo_de(pessoa) ||
		  @usuario_logado.eh_coordenador_de_encontro_de(pessoa) || 
		  @usuario_logado.grupos_que_coordena.count > 0 ||
		  @usuario_logado.esta_coordenando_agora_alguma_equipe_de_outra_pessoa(pessoa) || 
		  @usuario_logado == pessoa
	end

	def pode_criar_pessoas_em_grupo grupo_id
    return @usuario_logado.eh_super_admin? || 
      @usuario_logado.grupos_que_coordena.collect{|g| g.slug}.include?(grupo_id) || 
      @usuario_logado.grupos_que_coordena.collect{|g| g.id.to_s}.include?(grupo_id)
  end

	def pode_editar_pessoa pessoa
    return @usuario_logado == pessoa ||
        @usuario_logado.eh_super_admin? ||
        @usuario_logado.eh_coordenador_de_grupo_de(pessoa) ||
        @usuario_logado.eh_coordenador_de_encontro_de(pessoa) || 
        @usuario_logado.esta_coordenando_agora_alguma_equipe_de_outra_pessoa(pessoa) || 
        @usuario_logado.conjuge == pessoa
  end

	def pode_ver_participacao conjunto, pessoa
	  return @usuario_logado.eh_super_admin? ||
	  		@usuario_logado == pessoa || 
	      @usuario_logado.grupos_que_pode_ver.include?(conjunto.encontro.grupo) ||
	      pode_gerenciar_conjunto(conjunto)
	end

	def pode_gerenciar_conjunto conjunto
    if conjunto.tipo == 'ConjuntoPermanente'
      return @usuario_logado.eh_super_admin? || 
        conjunto.pessoas.include?(@usuario_logado) ||
        conjunto.encontro.coordenadores.include?(@usuario_logado) ||
        conjunto.encontro.grupo.coordenadores.include?(@usuario_logado)
    else
      return @usuario_logado.eh_super_admin? || 
        conjunto.coordenadores.include?(@usuario_logado) || 
        conjunto.encontro.coordenadores.include?(@usuario_logado) ||
        conjunto.encontro.grupo.coordenadores.include?(@usuario_logado)
    end
  end

  def participa_de_conjunto conjunto
    return conjunto.pessoas.include?(usuario_logado)
  end

  def pode_gerenciar_encontro encontro
  	return @usuario_logado.eh_super_admin? ||
  		encontro.coordenadores.include?(@usuario_logado) ||
  		encontro.grupo.coordenadores.include?(@usuario_logado)
	end

	def pode_excluir_pessoa pessoa
		return @usuario_logado.eh_super_admin? || 
			(@usuario_logado.eh_coordenador_de_grupo_de(pessoa) && 
				!pessoa.eh_super_admin?)
	end

	def pode_pesquisar_pessoas
	  return @usuario_logado.eh_super_admin? || 
	  	@usuario_logado.grupos_que_tem_encontros_que_coordena.count > 0
	end

	def pode_confirmar_ou_rejeitar_auto_sugestao auto_sugestao
		return @usuario_logado.eh_super_admin? ||
			auto_sugestao.grupo.coordenadores.include?(@usuario_logado) ||
			(auto_sugestao.encontro.present? && 
				auto_sugestao.encontro.coordenadores.include?(@usuario_logado))
	end

	def pode_editar_conjunto conjunto
    return @usuario_logado.eh_super_admin? ||
        conjunto.encontro.grupo.coordenadores.include?(@usuario_logado) ||
        conjunto.encontro.coordenadores.include?(@usuario_logado)
  end

  def pode_editar_facebook_de_pessoa pessoa_a_ser_editada
    return @usuario_logado.id != pessoa_a_ser_editada.id || 
    	@usuario_logado.eh_super_admin? || 
    	@usuario_logado.eh_coordenador_de_grupo_de(pessoa_a_ser_editada) || 
      pessoa_a_ser_editada.new_record?
  end

  def pode_alterar_estado_civil_de outra_pessoa
    return @usuario_logado.eh_super_admin? ||
        outra_pessoa.new_record? ||
        @usuario_logado.eh_coordenador_de_grupo_que_tem_encontros_de(outra_pessoa) || 
      	@usuario_logado.eh_coordenador_de_todos_os_grupos_de(outra_pessoa)
  end

  def pode_alterar_tipo_de_conjuge pessoa
    return @usuario_logado.eh_super_admin? ||
        pessoa.new_record? ||
        (
        	(@usuario_logado.eh_coordenador_de_grupo_que_tem_encontros_de(pessoa) || 
        		@usuario_logado.eh_coordenador_de_todos_os_grupos_de(pessoa)) &&
          (
          	pessoa.conjuge.blank? || 
          	@usuario_logado.eh_coordenador_de_grupo_que_tem_encontros_de(pessoa.conjuge) || 
          	@usuario_logado.eh_coordenador_de_todos_os_grupos_de(pessoa.conjuge)))
  end

  def pode_editar_recomendacoes conjunto
    return @usuario_logado.eh_super_admin? ||
      	conjunto.coordenadores.include?(@usuario_logado) || 
      	conjunto.encontro.grupo.coordenadores.include?(@usuario_logado)
  end

  def pode_excluir_encontro encontro
    return @usuario_logado.eh_super_admin? || 
    	encontro.grupo.coordenadores.include?(@usuario_logado)
  end

  def pode_editar_coordenador_de_conjunto conjunto
    return @usuario_logado.eh_super_admin? ||
        conjunto.encontro.coordenadores.include?(@usuario_logado) ||
        conjunto.encontro.grupo.coordenadores.include?(@usuario_logado)
  end

  def pode_gerenciar_grupo grupo
    return @usuario_logado.eh_super_admin? || 
	    grupo.coordenadores.include?(@usuario_logado)
  end

end