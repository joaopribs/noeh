#encoding: utf-8

class SessionsController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => :log_in
  skip_before_filter :verify_authenticity_token

  def log_in

    nome_facebook = params[:nome_facebook]
    email_facebook = params[:email_facebook]
    nascimento = params[:nascimento]
    url_foto_grande = params[:url_foto_grande]
    url_foto_pequena = params[:url_foto_pequena]

    usuario = nil

    usuarios = []

    if email_facebook.present?
      usuarios = Pessoa.where(email_facebook: email_facebook)
    end

    if usuarios.count == 1
      usuario = usuarios.first
    elsif nome_facebook.present?
      usuarios = Pessoa.where(nome_facebook: nome_facebook)

      if usuarios.count == 1
        usuario = usuarios.first
      elsif usuarios.count > 1
        usuarios = Pessoa.where(nome_facebook: nome_facebook, email_facebook: email_facebook)

        if usuarios.count == 1
          usuario = usuarios.first
        end

      end
    end

    if usuario.present?
      if nascimento.present? || email_facebook.present? || url_foto.present?
        if nascimento.present? && usuario.nascimento.blank?
          elementos = nascimento.split('/')
          mes = elementos[0]
          dia = elementos[1]
          ano = elementos[2]

          usuario.dia = dia
          usuario.mes = mes
          usuario.ano = ano
        end

        if email_facebook.present? && usuario.email.blank?
          usuario.email = email_facebook
        end

        if email_facebook.present? && usuario.email_facebook.blank?
          usuario.email_facebook = email_facebook
        end

        if (usuario.url_foto_grande.blank? || usuario.url_foto_pequena.blank?) &&
            (url_foto_grande.present? || url_foto_pequena.present?)
          usuario.url_foto_grande = url_foto_grande
          usuario.url_foto_pequena = url_foto_pequena
        end
      end

      usuario.ultimo_login = Time.zone.now

      usuario.save

      session[:usuario] = usuario

      msg = "ok"
    else
      msg = "não autorizado"
    end

    render :text => msg
  end

  def log_out

    session[:usuario] = nil
    redirect_to deslogado_url and return

  end

end