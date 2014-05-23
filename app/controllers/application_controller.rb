#encoding: utf-8

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :precisa_estar_logado, :escolher_cor, :iniciar_breadcrumbs

  def precisa_estar_logado

    @usuario_logado = session[:usuario]

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

end
