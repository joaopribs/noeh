#encoding: utf-8
require "open-uri"
require "uri"

class SessionsController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => [:log_in, :log_out, :pegar_usuario_facebook]
  skip_before_filter :nao_pode_ser_mobile, :only => [:log_in, :log_out, :login_com_id]
  skip_before_filter :verify_authenticity_token
  skip_before_filter :notificacao

  def log_in
    id_app_facebook = params[:id_app_facebook]
    nascimento = params[:nascimento]
    eh_homem = params[:eh_homem] == "true"
    url_foto_grande = params[:url_foto_grande]
    url_foto_pequena = params[:url_foto_pequena]
    url_facebook = params[:url_facebook]
    casado = params[:casado] == "true"

    usuario = pegar_usuario(params)

    if usuario.present?
      if nascimento.present? || url_foto_grande.present? || url_foto_pequena.present? || id_app_facebook.present?
        if nascimento.present? && usuario.nascimento.blank?
          elementos = nascimento.split('/')
          mes = elementos[0]
          dia = elementos[1]
          ano = elementos[2]

          usuario.dia = dia
          usuario.mes = mes
          usuario.ano = ano
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
            usuario.url_imagem_facebook_pequena = url_foto_pequena
          end
        end

        if id_app_facebook.present? && usuario.id_app_facebook.blank?
          usuario.id_app_facebook = id_app_facebook
        end
      end

      usuario.ultimo_login = Time.zone.now

      usuario.save

      session[:id_usuario] = usuario.id

      msg = "ok"
    else
      session[:id_app_facebook] = id_app_facebook
      session[:nascimento] = nascimento
      session[:eh_homem] = eh_homem
      session[:url_foto_grande] = url_foto_grande
      session[:url_foto_pequena] = url_foto_pequena
      session[:url_facebook] = url_facebook
      session[:casado] = casado

      if casado
        id_app_facebook_conjuge = params[:id_app_facebook_conjuge]
        nascimento_conjuge = params[:nascimento_conjuge]
        eh_homem_conjuge = params[:eh_homem_conjuge] == "true"
        url_foto_grande_conjuge = params[:url_foto_grande_conjuge]
        url_foto_pequena_conjuge = params[:url_foto_pequena_conjuge]
        url_facebook_conjuge = params[:url_facebook_conjuge]

        usuario_conjuge = pegar_usuario(
            {
              id_app_facebook: id_app_facebook_conjuge
            }
        )

        if usuario_conjuge.present?
          session[:id_usuario_conjuge] = usuario_conjuge.id
        else
          session[:id_app_facebook_conjuge] = params[:id_app_facebook_conjuge]
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
      if params[:mobile]
        redirect_to mobile_index_url and return
      else
        redirect_to root_url and return
      end
    else
      reset_session
      if params[:mobile]
        redirect_to mobile_deslogado_url and return
      else
        redirect_to deslogado_url and return
      end
    end
  end

  def pegar_usuario_facebook
    render text: pegar_usuario_facebook_pelo_id(params[:id_app_facebook])
  end

  private

    def pegar_usuario(params)
      id_app_facebook = params[:id_app_facebook]

      usuario = nil
      
      usuarios = []
      
      if id_app_facebook.present?
        usuarios = Pessoa.where(id_app_facebook: id_app_facebook)

        if usuarios.count == 1
          usuario = usuarios.first
        else
          usuario_facebook = pegar_usuario_facebook_pelo_id(id_app_facebook)

          if usuario_facebook.present?
            usuarios_pelo_usuario_fb = Pessoa.where(usuario_facebook: usuario_facebook)
            if usuarios_pelo_usuario_fb.count == 1
              usuario = usuarios_pelo_usuario_fb.first
            end
          end
        end
      end
      
      return usuario
    end

    def pegar_usuario_facebook_pelo_id(id_app_facebook)
      if id_app_facebook.present?
        usuario_facebook = tentar_pegar_usuario_facebook_pelo_id(id_app_facebook)

        # Se não conseguir, fazer login e tentar novamente
        if usuario_facebook == ""
          login_facebook
          usuario_facebook = tentar_pegar_usuario_facebook_pelo_id(id_app_facebook)
        end

        # Se ainda não conseguir, salvar o problema no banco de dados
        if usuario_facebook == ""
          Problema.new(problema: "Não conseguiu pegar usuário do Facebook pelo ID: #{id_app_facebook}").save
        end

        return usuario_facebook
      end
    end

    def tentar_pegar_usuario_facebook_pelo_id(id_app_facebook)
      puts "-------- tentando pegar as informações do facebook ----------"

      c = Curl::Easy.http_get("https://www.facebook.com/#{id_app_facebook}") do |curl| 
        curl.follow_location = true
        curl.enable_cookies = true
        curl.cookiefile = "cookie.txt"
        curl.cookiejar = "cookie.txt"
      
        curl.headers["User-Agent"] = request.env['HTTP_USER_AGENT']
        curl.headers["Referer"] = 'http://www.facebook.com'
        curl.verbose = true
      end

      ultima_url = c.last_effective_url

      c.close

      usuario_facebook = ultima_url.split("/").last

      if !usuario_facebook.starts_with?("profile.php")
        usuario_facebook = usuario_facebook.split("?").first
      end

      if usuario_facebook == "login.php"
        usuario_facebook = ""
      end

      return usuario_facebook
    end

end