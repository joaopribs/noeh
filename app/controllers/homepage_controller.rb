class HomepageController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => :deslogado

  def index

    if @usuario_logado.eh_super_admin
      redirect_to super_admin_inicial_url and return
    else
      redirect_to pessoa_path(@usuario_logado)
    end

  end

  def deslogado
    render :layout => false
  end

end