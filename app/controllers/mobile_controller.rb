class MobileController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => [:deslogado, :nao_cadastrado, :cadastro_proprio, :cadastro_proprio_confirmacao]
  skip_before_filter :nao_pode_ser_mobile

  layout 'mobile'

  def deslogado
    render layout: false
  end

  def index
    redirect_to mobile_pessoa_url(@usuario_logado)
  end

  def pessoa
    @pessoa = Pessoa.unscoped.find(params[:id])

    precisa_poder_ver_pessoa(@pessoa)
    return if performed?

    @participacoes = (@pessoa.conjuntos_permanentes + @pessoa.equipes).select{|c| @usuario_logado.permissoes.pode_ver_participacao(c, @pessoa)}

    if @pessoa.conjuge.present?
      @participacoes_conjuge = (@pessoa.conjuge.conjuntos_permanentes + @pessoa.conjuge.equipes).select{|c| @usuario_logado.permissoes.pode_ver_participacao(c, @pessoa)}
      @participacoes_conjuge = @participacoes_conjuge.sort_by!{|c| c.encontro.data_inicio}.reverse
    end
    
    @participacoes = @participacoes.sort_by!{|c| c.encontro.data_inicio}.reverse
  end

  def editar_pessoa
    @pessoa = Pessoa.unscoped.find(params[:id])

    precisa_poder_ver_pessoa(@pessoa)
    return if performed?

    @participacoes = (@pessoa.conjuntos_permanentes + @pessoa.equipes).select{|c| @usuario_logado.permissoes.pode_ver_participacao(c, @pessoa)}

    if @pessoa.conjuge.present?
      @participacoes_conjuge = (@pessoa.conjuge.conjuntos_permanentes + @pessoa.conjuge.equipes).select{|c| @usuario_logado.permissoes.pode_ver_participacao(c, @pessoa)}
      @participacoes_conjuge = @participacoes_conjuge.sort_by!{|c| c.encontro.data_inicio}.reverse
    end
    
    @participacoes = @participacoes.sort_by!{|c| c.encontro.data_inicio}.reverse
  end

  def conjunto
    @conjunto = ConjuntoPessoas.find(params[:id])
    precisa_poder_gerenciar_conjunto(@conjunto)
    return if performed?
  end

  def encontro
    @encontro = Encontro.find(params[:id])
    precisa_poder_gerenciar_encontro(@encontro)
    return if performed?
  end

  def grupo
    @grupo = Grupo.find(params[:id])
    precisa_poder_gerenciar_grupo(@grupo)
    return if performed?
  end

  def pesquisar_pessoas
    precisa_poder_pesquisar_pessoas
    return if performed?

    @parametros_pesquisa_pessoas = ParametrosPesquisaPessoas.new

    if params["pesquisa"].present?
      # pesquisar_pessoas_banco está na super classe
      @pessoas = pesquisar_pessoas_banco(params)
    end
  end

  def cadastro_proprio
    @pessoa = session[:pessoa]
    session[:pessoa] = nil
    @conjuge = session[:conjuge]
    session[:conjuge] = nil

    if @pessoa.nil?
      pessoa = Pessoa.unscoped.where(id_app_facebook: session[:id_app_facebook])

      if pessoa.count > 0
        redirect_to mobile_cadastro_proprio_confirmacao_url and return
      end

      @pessoa = Pessoa.new
      @pessoa.eh_homem = session[:eh_homem]
      @pessoa.id_app_facebook = session[:id_app_facebook]
      @pessoa.url_facebook = session[:url_facebook]
      @pessoa.url_imagem_facebook = session[:url_foto_grande]
      @pessoa.url_imagem_facebook_pequena = session[:url_foto_grande_pequena]

      @conjuge_ja_cadastrado = false

      if session[:casado]
        @eh_casal = true

        if session[:id_usuario_conjuge]
          @conjuge_ja_cadastrado = true
          @conjuge = Pessoa.where(session[:id_usuario_conjuge])
        else
          @conjuge = Pessoa.new
          @conjuge.eh_homem = session[:eh_homem_conjuge]
          @conjuge.id_app_facebook = session[:id_app_facebook_conjuge]
          @conjuge.url_facebook = session[:url_facebook_conjuge]
          @conjuge.url_imagem_facebook = session[:url_foto_grande_conjuge]
          @conjuge.url_imagem_facebook_pequena = session[:url_foto_grande_pequena_conjuge]
        end

        @pessoa.conjuge = @conjuge
      else
        @eh_casal = false
        @tipo_conjuge = 'form'
        @conjuge = Pessoa.new
        @conjuge.eh_homem = !@pessoa.eh_homem
      end
    end
  end

  private 

    def precisa_poder_ver_pessoa pessoa
      if pessoa.conjuge.present?
        if !@usuario_logado.permissoes.pode_ver_pessoa(pessoa) && !@usuario_logado.permissoes.pode_ver_pessoa(pessoa.conjuge)
          redirect_to mobile_index_url and return
        end
      else
        if !@usuario_logado.permissoes.pode_ver_pessoa(pessoa)
          redirect_to mobile_index_url and return
        end
      end
    end

    def precisa_poder_gerenciar_conjunto conjunto
      if !@usuario_logado.permissoes.pode_gerenciar_conjunto(conjunto)
        redirect_to mobile_index_url and return
      end
    end

    def precisa_poder_gerenciar_encontro encontro
      if !@usuario_logado.permissoes.pode_gerenciar_encontro(encontro)
        redirect_to mobile_index_url and return
      end
    end

    def precisa_poder_gerenciar_grupo grupo
      if !@usuario_logado.permissoes.pode_gerenciar_grupo(grupo)
        redirect_to mobile_index_url and return
      end
    end

    def precisa_poder_pesquisar_pessoas
      if !@usuario_logado.permissoes.pode_pesquisar_pessoas
        redirect_to mobile_index_url and return
      end
    end
end