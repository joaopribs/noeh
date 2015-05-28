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
    # File.open("cookie.txt", "w") {}

    # @cookie = IO.read "cookie.txt"

    byebug

    agent = Mechanize.new

    if !File.exist?('cookies.yml') || !agent.cookie_jar.load('cookies.yml')
      puts "nao tinha cookie"

      page = agent.get('https://facebook.com')
      fb_form = page.forms[0]  # select 1st form
      fb_form.email = 'noehsistemafblocal@gmail.com'  # fill in email
      fb_form.pass = 'S1st3m4N03h'  # fill password
      fb_form.checkbox_with(:id => 'persist_box').check
      page = agent.submit(fb_form, fb_form.buttons[0])

      agent.cookie_jar.save_as('cookies.yml')
    else
      puts "ja tinha cookie"
    end

    begin
      page = agent.get('https://facebook.com/joaopaulo.ribs')
      puts "conseguiu"
    rescue
      puts "nao conseguiu"
      page = agent.get('https://facebook.com')
      fb_form = page.forms[0]  # select 1st form
      fb_form.email = 'noehsistemafblocal@gmail.com'  # fill in email
      fb_form.pass = 'S1st3m4N03h'  # fill password
      fb_form.checkbox_with(:id => 'persist_box').check
      page = agent.submit(fb_form, fb_form.buttons[0])

      agent.cookie_jar.save_as('cookies.yml')
    end

    begin
      page = agent.get('https://facebook.com/joaopaulo.ribs')
      puts "conseguiu na segunda"
    rescue
      puts "nao conseguiu na segunda"
    end

    byebug

    #puts page.inspect  # inspect facebook main page's elements
    #puts page.forms.inspect  # then inspect form elements, these elements will be arranged in an array
    # fb_form = page.forms[0]  # select 1st form

    # fb_form.email = 'noehsistemafblocal@gmail.com'  # fill in email
    # fb_form.pass = 'S1st3m4N03h'  # fill password

    #puts fb_form.buttons.inspect  # then inspect button elements, these buttons are also arranged in an array
    #puts fb_form.buttons[0].inspect  # Log In is button[0] in button array

    #puts fb_form.inspect  # check the form to be submitted if login information is correct

    # page = agent.submit(fb_form, fb_form.buttons[0])

    #puts page.content  # show page content, then we can use this to make an html file
    puts page.inspect

    puts page.methods
  end

end