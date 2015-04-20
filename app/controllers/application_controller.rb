#encoding: utf-8

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :detectar_browser, :setar_super_admin, :precisa_estar_logado, :escolher_cor, :iniciar_breadcrumbs, :notificacao, :nao_pode_ser_mobile

  skip_before_filter :precisa_estar_logado, only: :pegar_informacoes_facebook_pelo_link
  skip_before_action :verify_authenticity_token, only: :pegar_informacoes_facebook_pelo_link

  MOBILE_BROWSERS = ["playbook", "windows phone", "android", "ipod", "iphone", "opera mini", "blackberry", "palm","hiptop","avantgo","plucker", "xiino","blazer","elaine", "windows ce; ppc;", "windows ce; smartphone;","windows ce; iemobile", "up.browser","up.link","mmp","symbian","smartphone", "midp","wap","vodafone","o2","pocket","kindle", "mobile","pda","psp","treo"]

  def detectar_browser
    agent = request.headers["HTTP_USER_AGENT"].downcase
  
    achou_nos_mobile = false

    MOBILE_BROWSERS.each do |m|
      if agent.match(m)
        achou_nos_mobile = true
        if session[:mobile].nil?
          session[:mobile] = true
        end
      end
    end
    
    if !achou_nos_mobile
      session[:mobile] = nil
    end
  end

  def nao_pode_ser_mobile
    if session[:mobile]
      session[:mobile] = nil
      redirect_to mobile_deslogado_url and return
    end
  end

  def setar_super_admin
    id_usuario_logado = session[:id_usuario]

    if id_usuario_logado.nil?
      return nil
    end

    begin
      @usuario_logado = Pessoa.find(id_usuario_logado)
    rescue ActiveRecord::RecordNotFound
      reset_session
      redirect_to deslogado_url and return
    end
  end

  def precisa_estar_logado

    if @usuario_logado.nil?
      redirect_to deslogado_url and return
    end

  end

  def escolher_cor

    cores = ["amarelo", "verde", "roxo", "branco", "laranja", "preto", "verde", "laranja", "amarelo", "preto", "branco",
             "roxo", "amarelo", "branco", "verde", "branco", "preto", "laranja", "branco", "roxo", "preto", "verde",
             "laranja", "amarelo"]

    # indice = Time.zone.now.day - 1
    # if indice > 23
    #   indice -= 23
    # end

    # indice += Time.zone.now.hour
    # if indice > 23
    #   indice -= 23
    # end

    indice = Time.zone.now.hour

    @cor = cores[indice]

  end

  def precisa_ser_super_admin
    if @usuario_logado.nil? || !@usuario_logado.eh_super_admin
      redirect_to root_url and return
    end
  end

  def iniciar_breadcrumbs
    @breadcrumbs = [{ titulo: "Página inicial", url: root_url, identificador: "root"}]
  end

  def adicionar_breadcrumb titulo, url, identificador
    @breadcrumbs << { titulo: titulo, url: url, identificador: identificador }
  end

  def notificacao
    if session[:notificacao]
      flash[:notice] = session[:notificacao]
      session[:notificacao] = nil
    end
  end

  def carregar_pessoas pessoas
    session[:id_pessoas] = pessoas.collect{|pessoa| pessoa.id}
    session[:id_pessoas_antes_do_filtro] = nil
  end

  def remover_pessoas_da_session id_pessoas
    session[:id_pessoas] = session[:id_pessoas] - id_pessoas
    session[:id_pessoas_antes_do_filtro] = nil
  end

  def pesquisar_pessoas_banco params
    pessoas = []

    if @parametros_pesquisa_pessoas.nil?
      @parametros_pesquisa_pessoas = ParametrosPesquisaPessoas.new
    end

    if params["pesquisa"].present?
      @parametros_pesquisa_pessoas.submeteu = true

      pesquisar_em_grupos = false
      pesquisar_em_instrumentos = false
      pesquisar_em_conjuntos = false
      pesquisar_recomendacoes_do_coordenador_permanente = false
      pesquisar_recomendacoes_equipes = false

      filtros_total = []

      filtros_pessoas = []

      if params[:nome].present?
        @parametros_pesquisa_pessoas.nome = params[:nome]
        filtros_pessoas << "(pessoas.nome LIKE '%#{@parametros_pesquisa_pessoas.nome}%' OR pessoas.nome_usual LIKE '%#{@parametros_pesquisa_pessoas.nome}%')"
      end

      if params[:generos].present?
        @parametros_pesquisa_pessoas.generos = params[:generos]
        if @parametros_pesquisa_pessoas.generos.count == 1
          filtros_pessoas << "pessoas.eh_homem = #{@parametros_pesquisa_pessoas.generos[0] == 'homem'}"
        end
      end

      if params[:estados_civis].present?
        @parametros_pesquisa_pessoas.estados_civis = params[:estados_civis]
        if @parametros_pesquisa_pessoas.estados_civis.count == 1
          filtros_pessoas << "pessoas.conjuge_id IS #{@parametros_pesquisa_pessoas.estados_civis[0] == 'casado' ? 'NOT ' : ''}NULL"
        end
      end

      if filtros_pessoas.count > 0
        filtros_total << "(#{filtros_pessoas.join(" AND ")})"
      end

      if params[:instrumentos].present?
        @parametros_pesquisa_pessoas.instrumentos = params[:instrumentos]
        filtros_instrumentos = []
        params[:instrumentos].each do |instrumento|
          filtros_instrumentos << "instrumentos.nome LIKE '%#{instrumento}%'"
        end
        filtros_total << "(#{filtros_instrumentos.join(" OR ")})"
        pesquisar_em_instrumentos = true
      end

      if params[:grupos]
        pesquisar_em_grupos = true
        @parametros_pesquisa_pessoas.grupos = params[:grupos]
        filtros_total << "(grupos.id IN (#{params[:grupos].join(", ")}))"
      else
        unless @usuario_logado.eh_super_admin?
          pesquisar_em_grupos = true
          filtros_total << "(grupos.id IN (#{@usuario_logado.grupos_que_pode_ver.collect{|g| g.id}.join(", ")}))"
        end
      end

      if params[:equipes]
        @parametros_pesquisa_pessoas.equipes = params[:equipes]

        pesquisar_em_conjuntos = true

        filtros_equipes = []

        params[:equipes].each do |equipe_procurando|
          partes = equipe_procurando.split("###")
          equipe = partes.first
          grupo = partes.last

          if equipe == 'coordPerm'
            filtros_equipes << "(conjuntos_pessoas.tipo = 'ConjuntoPermanente' AND relacoes_pessoa_conjunto.eh_coordenador = true AND grupos.id = #{grupo})"
            pesquisar_em_grupos = true
          else
            filtros_equipes << "(conjuntos_pessoas.equipe_padrao_relacionada = #{equipe})"
          end
        end
        filtros_total << "(#{filtros_equipes.join(" OR ")})"
      end

      if params[:recomendacoes]
        @parametros_pesquisa_pessoas.recomendacoes = params[:recomendacoes]

        filtros_recomendacoes = []

        params[:recomendacoes].each do |recomendacao_procurando|
          partes = recomendacao_procurando.split("###")
          equipe = partes.first
          grupo = partes.last

          if equipe == 'coordPerm'
            filtros_recomendacoes << "(recomendacoes_do_coordenador_permanente.recomenda_pra_coordenador = true AND recomendacoes_do_coordenador_permanente.conjunto_pessoas_id = conjuntos_pessoas.id AND conjuntos_pessoas.encontro_id = encontros.id AND encontros.grupo_id = #{grupo})"
            pesquisar_recomendacoes_do_coordenador_permanente = true
          else
            filtros_recomendacoes << "(recomendacoes_equipes.conjunto_pessoas_id = #{equipe})"
            pesquisar_recomendacoes_equipes = true
          end
        end

        filtros_total << "(#{filtros_recomendacoes.join(" OR ")})"
      end

      objetos = Pessoa

      if pesquisar_em_grupos
        objetos = objetos.joins(:grupos)
      end

      if pesquisar_em_instrumentos
        objetos = objetos.joins(:instrumentos)
      end

      if pesquisar_recomendacoes_do_coordenador_permanente
        objetos = objetos.joins(:recomendacao_do_coordenador_permanente)
          .joins('INNER JOIN conjuntos_pessoas ON recomendacoes_do_coordenador_permanente.conjunto_pessoas_id = conjuntos_pessoas.id')
          .joins('INNER JOIN encontros ON conjuntos_pessoas.encontro_id = encontros.id')
      end

      if pesquisar_em_conjuntos && !pesquisar_recomendacoes_do_coordenador_permanente
        objetos = objetos.joins(:conjuntos_pessoas)
      end

      if pesquisar_recomendacoes_equipes
        objetos = objetos.joins(:recomendacoes_equipes)
      end

      pessoas = objetos.where(filtros_total.join(" AND ")).distinct
    end

    return pessoas
  end

  def pegar_informacoes_facebook_pelo_link
    img_grande = ""
    img_pequena = ""
    nome = ""
    usuario_facebook = ""

    if params[:url]
      begin
        c = Curl::Easy.http_get(params[:url]) do |curl| 
          curl.follow_location = true
          curl.enable_cookies = true
          curl.cookiefile = "cookie.txt"
          curl.cookiejar = "cookie.txt"
        
          curl.headers["User-Agent"] = request.env['HTTP_USER_AGENT']
          curl.headers["Referer"] = 'http://www.facebook.com'
          curl.verbose = true
        end

        conteudo_pagina = c.body_str.force_encoding('UTF-8')

        img_grande = pegar_imagem_pela_classe('profilePic img', conteudo_pagina)
        # img_pequena = pegar_imagem_pela_classe('_s0 _2dpc _rw img', conteudo_pagina)
        nome = pegar_elemento_pelo_id('fb-timeline-cover-name', conteudo_pagina)

        if img_grande == "" 
          # Talvez precise fazer login e tentar de novo
          c = Curl::Easy.http_post("https://www.facebook.com/login.php?login_attempt=1", 
            Curl::PostField.content('email', APP_CONFIG['usuario_facebook_request']), 
            Curl::PostField.content('pass', APP_CONFIG['senha_facebook_request'])) do |curl| 

            curl.follow_location = true
            curl.enable_cookies = true
            curl.cookiefile = "cookie.txt"
            curl.cookiejar = "cookie.txt"
          
            curl.headers["User-Agent"] = request.env['HTTP_USER_AGENT']
            curl.headers["Referer"] = 'http://www.facebook.com'
            curl.verbose = true
          end

          puts '------------------------------------------------------------'
          c.url = "https://www.facebook.com/#{id_app_facebook}"
          c.http_get

          puts '------------------------------------------------------------'

          conteudo_pagina = c.body_str.force_encoding('UTF-8')

          img_grande = pegar_imagem_pela_classe('profilePic img', conteudo_pagina)
          # img_pequena = pegar_imagem_pela_classe('_s0 _2dpc _rw img', conteudo_pagina)
          nome = pegar_elemento_pelo_id('fb-timeline-cover-name', conteudo_pagina)
        end

        ultima_url = c.last_effective_url
        usuario_facebook = ultima_url.split("/").last.split("?").first
      rescue
      end
    end

    render json: {
      imagem_grande: img_grande, 
      imagem_pequena: img_pequena, 
      nome: nome,
      usuario: usuario_facebook
    }
  end

  private 

    def pegar_imagem_pela_classe(classe, conteudo_pagina)
      img = ""

      indice_classe_imagem = conteudo_pagina.index(classe)

      if indice_classe_imagem.present?
        indice_src_imagem = conteudo_pagina.index('src', indice_classe_imagem)

        if indice_src_imagem.present?
          indice_inicio = indice_src_imagem + 5
          indice_fim = conteudo_pagina.index('"', indice_inicio)

          img = conteudo_pagina[indice_inicio..indice_fim - 1]
        end
      end

      return img.gsub("&amp;", "&")
    end

    def pegar_elemento_pelo_id(id, conteudo_pagina)
      conteudo = ""

      indice_id = conteudo_pagina.index(id)

      if indice_id.present?
        indice_fim_tag = conteudo_pagina.index('>', indice_id)

        if indice_fim_tag.present?
          indice_inicio = indice_fim_tag + 1
          indice_fim = conteudo_pagina.index('<', indice_inicio)

          conteudo = conteudo_pagina[indice_inicio..indice_fim - 1]
        end
      end

      return conteudo
    end

end
