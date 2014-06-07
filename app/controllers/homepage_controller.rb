class HomepageController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => :deslogado

  def index
    redirect_to pessoa_path(@usuario_logado)
  end

  def deslogado
    render :layout => false
  end

  def limpar_notificacao
    flash[:notice] = nil
    render :text => "ok"
  end

end