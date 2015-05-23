require 'uri'

class HomepageController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => [:deslogado, :teste]
  skip_before_filter :nao_pode_ser_mobile, :only => :deslogado

  def index
    redirect_to pessoa_path(@usuario_logado)
  end

  def deslogado
    if session[:mobile]
      render 'mobile/deslogado', layout: false
    else
      render layout: false
    end
  end

  def limpar_notificacao
    flash[:notice] = nil
    render text: "ok"
  end

  def privacidade
  end

  def teste
  end

  def imprimircookie
    @cookie = IO.read "cookie.txt"
  end

end