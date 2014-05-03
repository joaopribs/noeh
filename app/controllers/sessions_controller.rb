#encoding: utf-8

class SessionsController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => :log_in
  skip_before_filter :verify_authenticity_token

  def log_in

    id_facebook = params[:id_facebook]

    usuario = Pessoa.where(:id_facebook => id_facebook).first

    if !usuario.nil?
      session[:id_facebook] = id_facebook

      if params[:nascimento] || params[:email]

        tem_que_salvar = false

        if params[:nascimento] && usuario.nascimento.blank?
          elementos = params[:nascimento].split('/')
          mes = elementos[0]
          dia = elementos[1]
          ano = elementos[2]

          usuario.dia = dia
          usuario.mes = mes
          usuario.ano = ano

          tem_que_salvar = true
        end

        if params[:email] && usuario.email.blank?
          usuario.email = params[:email]
          tem_que_salvar = true
        end

        if tem_que_salvar
          usuario.save
        end
      end

      msg = "ok"
    else
      msg = "não autorizado"
    end

    render :text => msg
  end

  def log_out

    session[:id_facebook] = nil
    redirect_to deslogado_url and return

  end

end