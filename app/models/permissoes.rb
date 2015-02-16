class Permissoes

	attr_accessor :usuario_logado

	def initialize(usuario_logado)
		@usuario_logado = usuario_logado
	end

	def pode_ver_pessoa pessoa
		if @usuario_logado.eh_super_admin? ||
		  @usuario_logado.eh_coordenador_de_grupo_de(pessoa) ||
		  @usuario_logado.eh_coordenador_de_encontro_de(pessoa) ||
		  @usuario_logado.grupos_que_coordena.count > 0 ||
		  @usuario_logado == pessoa
			return true
		end

		return false
	end

	def pode_criar_pessoas_em_grupo grupo_id
      if @usuario_logado.eh_super_admin? || 
        @usuario_logado.grupos_que_coordena.collect{|g| g.slug}.include?(grupo_id) || 
        @usuario_logado.grupos_que_coordena.collect{|g| g.id.to_s}.include?(grupo_id)
        return true
      end

      return false
    end

end