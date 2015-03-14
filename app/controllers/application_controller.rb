#encoding: utf-8

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :detectar_browser, :setar_super_admin, :precisa_estar_logado, :escolher_cor, :iniciar_breadcrumbs, :notificacao, :nao_pode_ser_mobile

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

end
