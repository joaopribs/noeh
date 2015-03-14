#encoding: utf-8
require "open-uri"
require "uri"

class SessionsController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => [:log_in, :log_out]
  skip_before_filter :nao_pode_ser_mobile, :only => [:log_in, :log_out]
  skip_before_filter :verify_authenticity_token
  skip_before_filter :notificacao

  def log_in
    nome_facebook = params[:nome_facebook]
    email_facebook = params[:email_facebook]
    nascimento = params[:nascimento]
    eh_homem = params[:eh_homem] == "true"
    url_foto_grande = params[:url_foto_grande]
    url_foto_pequena = params[:url_foto_pequena]
    url_facebook = params[:url_facebook]
    casado = params[:casado] == "true"

    usuario = pegar_usuario(params)

    if usuario.present?
      if nascimento.present? || email_facebook.present? || url_foto_grande.present? || url_foto_pequena.present?
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

        if url_foto_grande.present?
          nome_do_arquivo = URI::split(url_foto_grande)[5].split("/").last
          if usuario.foto_grande_file_name != nome_do_arquivo
            usuario.foto_grande = open(url_foto_grande)
            usuario.foto_grande_file_name = nome_do_arquivo
            usuario.url_imagem_facebook = url_foto_grande
          end
        end

        if url_foto_pequena.present?
          nome_do_arquivo = URI::split(url_foto_pequena)[5].split("/").last
          if usuario.foto_pequena_file_name != nome_do_arquivo
            usuario.foto_pequena = open(url_foto_pequena)
            usuario.foto_pequena_file_name = nome_do_arquivo
          end
        end
      end

      usuario.ultimo_login = Time.zone.now

      usuario.save

      session[:id_usuario] = usuario.id

      msg = "ok"
    else
      session[:nome_facebook] = nome_facebook
      session[:email_facebook] = email_facebook
      session[:nascimento] = nascimento
      session[:eh_homem] = eh_homem
      session[:url_foto_grande] = url_foto_grande
      session[:url_foto_pequena] = url_foto_pequena
      session[:url_facebook] = url_facebook
      session[:casado] = casado

      if casado
        nome_facebook_conjuge = params[:nome_facebook_conjuge]
        email_facebook_conjuge = params[:email_facebook_conjuge]
        nascimento_conjuge = params[:nascimento_conjuge]
        eh_homem_conjuge = params[:eh_homem_conjuge] == "true"
        url_foto_grande_conjuge = params[:url_foto_grande_conjuge]
        url_foto_pequena_conjuge = params[:url_foto_pequena_conjuge]
        url_facebook_conjuge = params[:url_facebook_conjuge]

        usuario_conjuge = pegar_usuario(
            {
              nome_facebook: nome_facebook_conjuge,
              email_facebook: email_facebook_conjuge
            }
        )

        if usuario_conjuge.present?
          session[:id_usuario_conjuge] = usuario_conjuge.id
        else
          session[:nome_facebook_conjuge] = params[:nome_facebook_conjuge]
          session[:email_facebook_conjuge] = params[:email_facebook_conjuge]
          session[:nascimento_conjuge] = params[:nascimento_conjuge]
          session[:eh_homem_conjuge] = params[:eh_homem_conjuge]
          session[:url_foto_grande_conjuge] = params[:url_foto_grande_conjuge]
          session[:url_foto_pequena_conjuge] = params[:url_foto_pequena_conjuge]
          session[:url_facebook_conjuge] = params[:url_facebook_conjuge]
        end

      end

      msg = "não existe"
    end

    render :text => msg
  end

  def log_out
    reset_session
    redirect_to deslogado_url and return
  end

  def login_com_id
    id = params[:id]
    usuario = Pessoa.where(id: id).first

    if usuario.present?
      session[:id_usuario] = usuario.id
      redirect_to root_url and return
    else
      reset_session
      redirect_to deslogado_url and return
    end
  end

  private

  def pegar_usuario(params)
    email_facebook = params[:email_facebook]
    nome_facebook = params[:nome_facebook]
    
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
    
    return usuario
  end

end