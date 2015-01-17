#encoding: utf-8

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :setar_super_admin, :precisa_estar_logado, :escolher_cor, :iniciar_breadcrumbs, :notificacao

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

    indice = Time.now.day - 1
    if indice > 23
      indice -= 23
    end

    indice += Time.now.hour
    if indice > 23
      indice -= 23
    end

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

end
