#encoding: utf-8
require "open-uri"
require "rmagick"

class PessoasController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => [:cadastrar_novo, :create, :cadastrar_novo_confirmacao, :cadastrar_novo_confirmacao_mobile]
  before_action :set_entidades, :adicionar_breadcrumbs_entidades
  skip_before_action :adicionar_breadcrumbs_entidades, only: [:cadastrar_novo, :create, :cadastrar_novo_confirmacao, :cadastrar_novo_confirmacao_mobile]
  skip_before_action :verify_authenticity_token, only: [:lista_pessoas_js]
  skip_before_filter :nao_pode_ser_mobile, only: [:cadastrar_novo, :create, :cadastrar_novo_confirmacao_mobile, :edit, :update]

  # GET /pessoas
  # GET /pessoas.json
  def index
    precisa_ser_super_admin
    return if performed?

    carregar_pessoas(Pessoa.all)
    @tipo_pagina = "lista_pessoas"
  end
  # GET /pessoas/1

  # GET /pessoas/1.json
  def show
    precisa_poder_ver_pessoa @pessoa
    return if performed?

    adicionar_breadcrumb_de_ver_pessoa
  end

  # GET /pessoas/new
  def new
    precisa_poder_criar_pessoas
    return if performed?

    adicionar_breadcrumb "Criar nova pessoa", new_pessoa_url, "criar"

    @pessoa = Pessoa.new
    @conjuge = Pessoa.new
    @adicionar = true
  end

  # GET /pessoas/1/edit
  def edit
    precisa_poder_editar_pessoa @pessoa
    return if performed?

    @eh_casal = @pessoa.conjuge.present?

    if @eh_casal
      precisa_poder_editar_pessoa @pessoa.conjuge
      return if performed?

      @conjuge = @pessoa.conjuge
      @tipo_conjuge = 'form'
    else
      @conjuge = Pessoa.new
    end

    adicionar_breadcrumb_de_ver_pessoa
    adicionar_breadcrumb "Editar", edit_pessoa_url(@pessoa), "editar"

    mobile = params[:mobile]

    if mobile.present?
      render template: 'pessoas/mobile/editar', layout: 'mobile'
    end

  end

  # POST /pessoas
  # POST /pessoas.json
  def create
    if !eh_auto_inserido
      precisa_poder_criar_pessoas
      return if performed?
    end

    adicionar_breadcrumb "Criar nova pessoa", new_pessoa_url, "criar"

    @pessoa = criar_pessoa("pessoa")

    @eh_casal = params[:casado_ou_solteiro] == 'casado'
    @os_dois = params[:os_dois] == 'true'

    @pessoa_valida = @pessoa.valid?

    if !@eh_casal
      setar_variaveis_auto_inserido()
    end

    if @eh_casal
      msg_sucesso = "Casal inserido com sucesso"

      @tipo_conjuge = params[:tipo_de_conjuge_escolhido]

      if @tipo_conjuge == "ja_cadastrado" && !params[:id_conjuge].blank?
        @conjuge = Pessoa.find(params[:id_conjuge])
        @tipo_conjuge = 'ja_cadastrado'
      else
        @conjuge = criar_pessoa("conjuge")
        @tipo_conjuge = 'form'
      end

      if @pessoa_valida
        @conjuge.rua = @pessoa.rua
        @conjuge.numero = @pessoa.numero
        @conjuge.bairro = @pessoa.bairro
        @conjuge.cidade = @pessoa.cidade
        @conjuge.estado = @pessoa.estado
        @conjuge.cep = @pessoa.cep
      end

      @conjuge_valido = @conjuge.valid?

      setar_variaveis_auto_inserido()

      @casal_valido = @pessoa_valida && @conjuge_valido

      if @casal_valido
        @pessoa.conjuge = @conjuge
        @conjuge.conjuge = @pessoa
      end
    else
      msg_sucesso = "Pessoa inserida com sucesso"
      @conjuge = Pessoa.new
    end

    respond_to do |format|
      salvou = false
      if @eh_casal && @casal_valido
        salvou = @pessoa.save && @conjuge.save
      elsif @pessoa_valida 
        salvou = @pessoa.save
      end

      if salvou

        atualizar_relacionamentos(@pessoa, "pessoa")

        atualizar_fotos(@pessoa)
        if @eh_casal
          atualizar_relacionamentos(@conjuge, "conjuge")
          atualizar_fotos(@conjuge)
        end

        criar_relacoes_auto_inserir

        if defined? @conjunto
          if @conjunto.tipo == 'CoordenacaoEncontro'
            texto_adicionado = "à coordenação do encontro #{@conjunto.encontro.nome} e ao grupo #{@conjunto.encontro.grupo.nome}"
          elsif @conjunto.tipo == 'Equipe'
            texto_adicionado = "à equipe #{@conjunto.nome} do encontro #{@conjunto.encontro.nome} e ao grupo #{@conjunto.encontro.grupo.nome}"
          else
            texto_adicionado = "a #{@conjunto.tipo_do_conjunto} #{@conjunto.nome} do encontro #{@conjunto.encontro.nome} e ao grupo #{@conjunto.encontro.grupo.nome}"
          end

          salvar_relacao_conjunto(@pessoa, @conjunto, @os_dois, false)

          if @eh_casal
            msg_sucesso = "Casal criado e adicionado #{texto_adicionado} com sucesso"
          else
            msg_sucesso = "Pessoa criada e adicionada #{texto_adicionado} com sucesso"
          end

        elsif defined? @grupo

          salvar_relacao_grupo(@pessoa, @grupo, @os_dois, false)
          if @eh_casal
            msg_sucesso = "Casal criado e adicionado ao grupo #{@grupo.nome} com sucesso"
          else
            msg_sucesso = "Pessoa criada e adicionada ao grupo #{@grupo.nome} com sucesso"
          end

        end

        format.html { redirect_to pagina_retorno, notice: msg_sucesso }
        format.json { render action: 'show', status: :created, location: @pessoa }
      else
        if eh_auto_inserido
          if params.has_key?(:mobile)
            format.html { render 'pessoas/mobile/cadastrar_novo', layout: 'mobile' }
          else
            format.html { render action: 'cadastrar_novo' }
          end
        else
          format.html { render action: 'new' }
          format.json { render json: @pessoa.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /pessoas/1
  # PATCH/PUT /pessoas/1.json
  def update
    precisa_poder_editar_pessoa @pessoa
    return if performed?

    adicionar_breadcrumb_de_ver_pessoa
    adicionar_breadcrumb "Editar", edit_pessoa_url(@pessoa), "editar"

    tinha_facebook_antes = @pessoa.tem_informacoes_facebook

    @pessoa = atualizar_pessoa(@pessoa, "pessoa")

    @pessoa = remover_facebook_se_necessario(@pessoa, tinha_facebook_antes)

    precisa_salvar_pessoa = true
    precisa_salvar_velho_conjuge = false
    precisa_salvar_conjuge = false

    @eh_casal = params[:casado_ou_solteiro] == 'casado'
    @os_dois = params[:os_dois] == 'true'

    if !@eh_casal
      setar_variaveis_auto_inserido()
    end

    if @eh_casal
      precisa_salvar_conjuge = true

      setar_variaveis_auto_inserido()

      @tipo_conjuge = params[:tipo_de_conjuge_escolhido]

      if @tipo_conjuge == "ja_cadastrado" && !params[:id_conjuge].blank?
        @conjuge = Pessoa.find(params[:id_conjuge])

        precisa_poder_editar_pessoa @conjuge
        precisa_poder_editar_pessoa @pessoa.conjuge
        return if performed?

        if @pessoa.valid?
          @velho_conjuge = @pessoa.conjuge
          if @velho_conjuge.present?
            @velho_conjuge.conjuge = nil
            precisa_salvar_velho_conjuge = true
          end
        end

        @tipo_conjuge = 'ja_cadastrado'
      else
        @conjuge = @pessoa.conjuge

        if @conjuge.present?
          precisa_poder_editar_pessoa @conjuge
          return if performed?

          @conjuge = atualizar_pessoa(@conjuge, "conjuge")
        else
          @conjuge = criar_pessoa("conjuge")
        end

        @conjuge = remover_facebook_se_necessario(@conjuge, @conjuge.tem_informacoes_facebook)

        if !@conjuge.valid?
          precisa_salvar_pessoa = false
        end

        @tipo_conjuge = 'form'
      end

      if @pessoa.valid?
        @conjuge.rua = @pessoa.rua
        @conjuge.numero = @pessoa.numero
        @conjuge.bairro = @pessoa.bairro
        @conjuge.cidade = @pessoa.cidade
        @conjuge.estado = @pessoa.estado
        @conjuge.cep = @pessoa.cep
      end

      if @pessoa.valid? && @conjuge.valid?
        @pessoa.conjuge = @conjuge
        @conjuge.conjuge = @pessoa
      end

      msg_sucesso = "Casal editado com sucesso"
    else
      @conjuge = @pessoa.conjuge

      if @conjuge.nil?
        @conjuge = Pessoa.new
      else
        if @pessoa.valid? && @pessoa.conjuge.present?
          @pessoa.conjuge.conjuge = nil
          @pessoa.conjuge = nil
          precisa_salvar_conjuge = true
        end
      end

      msg_sucesso = "Pessoa editada com sucesso"
    end

    respond_to do |format|
      salvou = false
      if precisa_salvar_pessoa
        salvou = @pessoa.save
      end
      if precisa_salvar_conjuge
        salvou = @conjuge.save
      end
      if precisa_salvar_velho_conjuge
        salvou = @velho_conjuge.save
      end

      if salvou || (!precisa_salvar_pessoa && !precisa_salvar_conjuge && !precisa_salvar_velho_conjuge)
        if precisa_salvar_pessoa
          atualizar_fotos(@pessoa)
          atualizar_relacionamentos(@pessoa, "pessoa")
        end

        if precisa_salvar_conjuge
          atualizar_fotos(@conjuge)
          atualizar_relacionamentos(@conjuge, "conjuge")
        end

        if precisa_salvar_velho_conjuge
          atualizar_fotos(@velho_conjuge)
        end

        if defined? @conjunto
          salvar_relacao_conjunto(@pessoa, @conjunto, @os_dois, false)
        elsif defined? @grupo
          salvar_relacao_grupo(@pessoa, @grupo, @os_dois, false)
        end

        criar_relacoes_auto_inserir

        format.html { redirect_to pagina_retorno, notice: msg_sucesso }
        format.json { head :no_content }
      else
        if params.has_key?(:mobile)
          format.html { render 'pessoas/mobile/editar', layout: 'mobile' }
        else
          format.html { render action: 'edit' }
        end
        format.json { render json: @pessoa.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pessoas/1
  # DELETE /pessoas/1.json
  def destroy
    if @usuario_logado.permissoes.pode_excluir_pessoa(@pessoa)
      @pessoa.destroy

      id_pessoas_a_remover_da_session = [@pessoa.id]
      if @pessoa.conjuge.present?
        id_pessoas_a_remover_da_session << @pessoa.conjuge.id
      end

      remover_pessoas_da_session(id_pessoas_a_remover_da_session)

      numero_pagina = 1

      msg_sucesso = @pessoa.conjuge.present? ? 'Casal excluído com sucesso' : 'Pessoa excluída com sucesso'

      flash[:notice] = msg_sucesso

      respond_to do |format|
        # format.html { redirect_to pessoas_url, notice: msg_sucesso, status: 303 } # Status 303 eh pq ta vindo de um method DELETE e redirecionando pra um GET
        format.json { render json: {novaPagina: numero_pagina, msgSucesso: msg_sucesso}, status: :ok }
      end
    else
      redirect_to root_url and return
    end
  end

  def cadastrar_novo
    pessoa = Pessoa.unscoped.where(id_app_facebook: session[:id_app_facebook])

    if pessoa.count > 0
      if params.has_key?(:mobile)
        redirect_to cadastrar_novo_confirmacao_mobile_url and return
      else
        redirect_to cadastrar_novo_confirmacao_url and return
      end
    end

    @pessoa = Pessoa.new
    @pessoa.eh_homem = session[:eh_homem]
    @pessoa.id_app_facebook = session[:id_app_facebook]
    @pessoa.url_facebook = session[:url_facebook]
    @pessoa.url_imagem_facebook = session[:url_foto_grande]

    if session[:casado]
      @eh_casal = true

      if session[:id_usuario_conjuge]
        @tipo_conjuge = 'ja_cadastrado'
        @conjuge = Pessoa.where(session[:id_usuario_conjuge])
      else
        @tipo_conjuge = 'form'

        @conjuge = Pessoa.new
        @conjuge.eh_homem = session[:eh_homem_conjuge]
        @conjuge.id_app_facebook = session[:id_app_facebook_conjuge]
        @conjuge.url_facebook = session[:url_facebook_conjuge]
        @conjuge.url_imagem_facebook = session[:url_foto_grande_conjuge]
      end

      @pessoa.conjuge = @conjuge
    else
      @eh_casal = false
      @tipo_conjuge = 'form'
      @conjuge = Pessoa.new
      @conjuge.eh_homem = !@pessoa.eh_homem
    end

    mobile = params[:mobile]

    if mobile.present?
      render template: 'pessoas/mobile/cadastrar_novo', layout: 'mobile'
    end
  end

  def cadastrar_novo_confirmacao
  end

  def cadastrar_novo_confirmacao_mobile
    render template: 'pessoas/mobile/cadastrar_novo_confirmacao', layout: 'mobile'
  end

  def pesquisa_pessoas_por_nome
    condicoes = []
    id_pessoas_ignorar = []
    id_pessoas_incluir = []

    if params.has_key? :query
      condicoes.concat ["(pessoas.nome LIKE '%#{params[:query]}%' OR pessoas.nome_usual LIKE '%#{params[:query]}%')"]
    end

    if params.has_key? :id_grupo_ignorar
      grupo_ignorar = Grupo.find(params[:id_grupo_ignorar])
      id_pessoas_ignorar.concat grupo_ignorar.pessoas.collect{ |p| p.id }
    end

    if params.has_key? :id_conjunto
      conjunto = ConjuntoPessoas.find(params[:id_conjunto])
      id_pessoas_ignorar.concat conjunto.pessoas.collect{|p| p.id}
    end

    if params.has_key? :pessoa_ignorar
      id_pessoas_ignorar.concat [params[:pessoa_ignorar]]
    end

    if params.has_key? :id_pessoas_ignorar
      id_pessoas_ignorar.concat(params[:id_pessoas_ignorar])
    end

    if id_pessoas_ignorar.count > 0
      condicoes.concat ["pessoas.id NOT IN (#{id_pessoas_ignorar.join(",")})"]
    end

    if id_pessoas_incluir.count > 0
      condicoes.concat ["pessoas.id IN (#{id_pessoas_incluir.join(",")})"]
    end

    if params.has_key? :ignorar_casais
      condicoes.concat ["pessoas.conjuge_id IS NULL"]
    end

    sql = condicoes.join(" AND ")
    pessoas = Pessoa.where(sql).order("pessoas.nome ASC")

    if pessoas.length == 0
      descricao_quantidade = "nenhuma"
    elsif pessoas.length > 5
      descricao_quantidade = "extrapolou"
    else
      descricao_quantidade = pessoas.length.to_s
    end

    objetos = []

    pessoas[0..4].each { |pessoa|
      if pessoa.conjuge.present?
        conjuge = pessoa.conjuge.attributes

        if pessoa.conjuge.foto_perfil.present?
          conjuge = conjuge.merge({url_foto_grande: pessoa.conjuge.foto_perfil.foto.url})
          conjuge = conjuge.merge({url_foto_pequena: pessoa.conjuge.foto_perfil.foto.url(:thumb)})
        end
      else
        conjuge = nil
      end

      pessoa_hash = pessoa.attributes

      if pessoa.foto_perfil.present?
        pessoa_hash = pessoa_hash.merge({url_foto_grande: pessoa.foto_perfil.foto.url})
        pessoa_hash = pessoa_hash.merge({url_foto_pequena: pessoa.foto_perfil.foto.url(:thumb)})
      end

      if params.has_key? :id_conjunto
        conjunto = ConjuntoPessoas.find(params[:id_conjunto])
        encontro = conjunto.encontro
        
        pessoa_hash = pessoa_hash.merge({equipes: pessoa.equipes.where(encontro: encontro)})
        pessoa_hash = pessoa_hash.merge({conjuntos_permanentes: pessoa.conjuntos_permanentes.where(encontro: encontro)})
        pessoa_hash = pessoa_hash.merge({denominacao_conjuntos_permanentes: encontro.denominacao_conjuntos_permanentes})
        pessoa_hash = pessoa_hash.merge({grupos: pessoa.grupos.where("grupo_id != #{encontro.grupo.id}")})
      else
        pessoa_hash = pessoa_hash.merge({grupos: pessoa.grupos})
      end

      objetos << pessoa_hash.merge({conjuge: conjuge})
    }

    respond_to do |format|
      format.json { render json: {pessoas: objetos, descricao_quantidade: descricao_quantidade} }
    end
  end

  def lista_pessoas
    if session[:id_pessoas_antes_do_filtro].nil? || session[:id_pessoas_antes_do_filtro].empty?
      session[:id_pessoas_antes_do_filtro] = session[:id_pessoas]
    end

    @tipo_pagina = params[:tipo_pagina]

    if @tipo_pagina == 'pessoas_a_confirmar'
      # Quando vamos em pessoas a confirmar, eles estão auto_inserido = 1, e isso fica fora do default scope, por isso
      # temos que forçar pra pegar os cônjuges
      forcar_conjuges = true
    else
      forcar_conjuges = false
    end

    @pessoas = Pessoa.pegar_pessoas(session[:id_pessoas], forcar_conjuges)

    @total = @pessoas.count
    @numero_casais = @pessoas.select{|p| p.conjuge != nil && session[:id_pessoas].include?(p.conjuge_id)}.count / 2

    @mostrar_filtro = params[:mostrar_filtro].nil? ? true : params[:mostrar_filtro] == "true"
    @fazer_paginacao = params[:fazer_paginacao].nil? ? true : params[:fazer_paginacao] == "true"

    if @fazer_paginacao
      begin
        @pessoas = @pessoas.page params[:page]
      rescue NoMethodError
        @pessoas = Kaminari.paginate_array(@pessoas).page params[:page]
      end
    end

    @mostrar_conjuges = params[:mostrar_conjuges].nil? ? true : params[:mostrar_conjuges] == "true"

    if @tipo_pagina == 'lista_pessoas'
      if @usuario_logado.eh_super_admin?
        @link = {
            texto: 'Criar nova pessoa',
            path: new_pessoa_path,
            classe: 'link_novo link_nova_pessoa'
        }
      end
    end

    if params.has_key?(:grupo_id)
      @grupo = Grupo.find(params[:grupo_id])
    end

    if params.has_key?(:conjunto_id)
      @conjunto = ConjuntoPessoas.find(params[:conjunto_id])
    end

    if params.has_key?(:query) && !params[:query].blank?
      @query = params[:query]
    end

    render :layout => false
  end

  def lista_pessoas_js
  end

  def filtrar_pessoas
    limpar_filtro = params[:limpar_filtro]

    if limpar_filtro
      session[:id_pessoas] = session[:id_pessoas_antes_do_filtro]
    else
      if session[:id_pessoas_antes_do_filtro].nil? || session[:id_pessoas_antes_do_filtro].empty?
        session[:id_pessoas_antes_do_filtro] = session[:id_pessoas]
      end

      pessoas = Pessoa.pegar_pessoas(session[:id_pessoas_antes_do_filtro], false)

      query = ActiveSupport::Inflector.transliterate(params[:query].downcase)

      if pessoas && query && query.length >= 3
        session[:id_pessoas] = pessoas.select{|pessoa| ActiveSupport::Inflector.transliterate(pessoa.nome.downcase).include?(query) ||
            ActiveSupport::Inflector.transliterate(pessoa.nome_usual.downcase).include?(query)}
          .collect{|pessoa| pessoa.id}
      end
    end

    render text: 'ok'
  end

  def confirmar_participacoes
    confirmar_ou_rejeitars = params[:confirmar_ou_rejeitar]
    id_conjuntos = params[:conjunto]
    eh_coordenadors = params[:eh_coordenador]

    pessoa = nil

    contador_confirmadas = 0
    contador_rejeitadas = 0

    if confirmar_ou_rejeitars.present?
      confirmar_ou_rejeitars.each do |id_auto_sugestao, confirmar_ou_rejeitar| 
        if pessoa.nil?
          pessoa = AutoSugestao.find(id_auto_sugestao).pessoa
        end

        if confirmar_ou_rejeitar == "confirmar"
          id_conjunto = id_conjuntos.present? ? id_conjuntos[id_auto_sugestao] : nil
          eh_coordenador = eh_coordenadors.present? ? eh_coordenadors[id_auto_sugestao] : nil
          confirmar_auto_sugestao(id_auto_sugestao, id_conjunto, eh_coordenador)
          contador_confirmadas += 1
        else
          rejeitar_auto_sugestao(id_auto_sugestao)
          contador_rejeitadas += 1
        end
      end
    end

    texto_confirmadas = nil
    texto_rejeitadas = nil
    
    if contador_confirmadas > 0
      texto_confirmadas = "#{contador_confirmadas} "
      if contador_confirmadas == 1 
        texto_confirmadas += 'participacão confirmada'
      else
        texto_confirmadas += 'participacões confirmadas'
      end
    end

    if contador_rejeitadas > 0
      texto_rejeitadas = "#{contador_rejeitadas} "
      if contador_rejeitadas == 1 
        if contador_confirmadas == 0
          texto_rejeitadas += 'participação '
        end
        texto_rejeitadas += 'rejeitada'
      else
        if contador_confirmadas == 0 
          texto_rejeitadas += 'participações '
        end
        texto_rejeitadas += 'rejeitadas'
      end
    end

    separador = ""
    msg_sucesso = ""
    [texto_confirmadas, texto_rejeitadas].each do |texto|
      if texto.present?
        msg_sucesso += "#{separador}#{texto}"
        separador = " e "
      end
    end

    respond_to do |format|
      if pessoa.present?
        format.html { redirect_to pessoa, notice: msg_sucesso }
      else
        format.html { redirect_to root_url, notice: msg_sucesso }
      end
    end
  end

  def confirmar_auto_sugestao(id_auto_sugestao, id_conjunto, eh_coordenador)
    auto_sugestao = AutoSugestao.find(id_auto_sugestao)

    precisa_poder_confirmar_ou_rejeitar_auto_sugestao(auto_sugestao)
    return if performed?

    pessoa = Pessoa.unscoped.find(auto_sugestao.pessoa_id)

    begin
      conjuge_da_auto_sugestao = Pessoa.unscoped.find(auto_sugestao.conjuge_id)
    rescue
      conjuge_da_auto_sugestao = nil
    end

    grupo = auto_sugestao.grupo

    texto_sugestao = auto_sugestao.sugestao
    
    begin
      conjunto = ConjuntoPessoas.find(id_conjunto)
    rescue
      conjunto = nil
    end

    eh_coordenador = eh_coordenador == "true"

    salvar_relacoes_ao_confirmar_auto_sugestao pessoa, grupo, conjunto, texto_sugestao, eh_coordenador

    if pessoa.auto_inserido
      pessoa.auto_inserido = false
      pessoa.save

      begin
        conjuge_da_pessoa = Pessoa.unscoped.find(pessoa.conjuge_id)
        if conjuge_da_pessoa.present?
          conjuge_da_pessoa.auto_inserido = false
          conjuge_da_pessoa.save        
        end
      rescue
      end
    end

    if conjuge_da_auto_sugestao.present?
      salvar_relacoes_ao_confirmar_auto_sugestao conjuge_da_auto_sugestao, grupo, conjunto, texto_sugestao, eh_coordenador

      if conjuge_da_auto_sugestao.auto_inserido
        conjuge_da_auto_sugestao.auto_inserido = false
        conjuge_da_auto_sugestao.save
      end
    end

    auto_sugestao.destroy
  end

  def rejeitar_auto_sugestao(id_auto_sugestao)
    auto_sugestao = AutoSugestao.find(id_auto_sugestao)

    precisa_poder_confirmar_ou_rejeitar_auto_sugestao(auto_sugestao)
    return if performed?

    pessoa = Pessoa.unscoped.find(auto_sugestao.pessoa_id)

    auto_sugestao.destroy

    devia_deletar_pessoa = pessoa.auto_inserido && pessoa.quantas_auto_sugestoes_individuais_ou_casal == 0

    begin 
      conjuge = Pessoa.unscoped.find(pessoa.conjuge_id)
      devia_deletar_conjuge = conjuge.auto_inserido && conjuge.quantas_auto_sugestoes_individuais_ou_casal == 0
    rescue
      conjuge = nil
    end

    if pessoa.auto_inserido && devia_deletar_pessoa
      if conjuge.nil?
        pessoa.destroy
      else
        if conjuge.auto_inserido && devia_deletar_conjuge
          pessoa.destroy
          conjuge.destroy
        end
      end
    end
  end

  def pessoas_a_confirmar
    adicionar_breadcrumb "Pessoas aguardando confirmação", pessoas_a_confirmar_url, "confirmar"

    carregar_pessoas(@usuario_logado.pessoas_a_confirmar)
  end

  def pesquisar_pessoas
    precisa_poder_pesquisar_pessoas
    return if performed?

    adicionar_breadcrumb "Pesquisar pessoas", pesquisar_pessoas_url, "pesquisar"

    @parametros_pesquisa_pessoas = ParametrosPesquisaPessoas.new

    if params["pesquisa"].present?
      # pesquisar_pessoas_banco está na super classe
      pessoas = pesquisar_pessoas_banco(params)
      carregar_pessoas(pessoas)
    end

  end

  def fotos
    @tipo_pessoa = params[:tipo_pessoa]
    @refresh = params[:refresh] == "1"

    if params[:id].blank?
      render :nothing
    end

    precisa_poder_editar_pessoa @pessoa
    return if performed?

    @fotos = []
    foto_perfil_id = nil

    foto_perfil = @pessoa.foto_perfil

    if foto_perfil.present?
      foto_perfil_id = foto_perfil.id
      @fotos << foto_perfil
    end

    @pessoa.fotos.where.not(id: foto_perfil_id).each do |foto|
      @fotos << foto
    end

    render layout: false
  end

  def deletar_foto
    precisa_poder_editar_pessoa @pessoa
    return if performed?

    if params[:foto_id]
      foto = Foto.find(params[:foto_id])
      if foto.nil?
        render text: "nao achou"
      else
        foto.destroy
        render text: "ok"
      end
    end
  end

  def setar_foto_principal
    precisa_poder_editar_pessoa @pessoa
    return if performed?

    if params[:foto_id]
      foto = Foto.find(params[:foto_id])
      if foto.nil?
        render text: "nao achou"
      else
        @pessoa.foto_perfil = foto
        @pessoa.save
        render text: "ok"
      end
    end
  end

  def upload_foto
    @tipo_pessoa = params[:tipo_pessoa]

    precisa_poder_editar_pessoa @pessoa
    return if performed?

    begin
      [:crop_w, :crop_h].each do |atributo|
        if params[atributo].blank? || params[atributo].to_i == 0
          raise
        end
      end

      imagem = Magick::Image.read(params[:foto].tempfile.path).first
      imagem.auto_orient!

      largura = imagem.columns
      altura = imagem.rows
      if altura >= largura && altura > 500
        fit = 500
      elsif largura >= altura && largura > 600
        fit = 600
      end

      if fit.present?
        imagem.resize_to_fit!(fit)
      end

      imagem.crop!(params[:crop_x].to_i, params[:crop_y].to_i, params[:crop_w].to_i, params[:crop_h].to_i)
      imagem.resize_to_fit!(200)
      imagem.write(params[:foto].original_filename)

      arquivo_redimensionado = File.open(imagem.filename)

      foto = Foto.new
      foto.foto = arquivo_redimensionado

      arquivo_redimensionado.close

      conseguiu = false
      tentativa = 0

      while tentativa < 3 and !conseguiu do
        begin
          @pessoa.fotos << foto
          if @pessoa.foto_perfil.blank?
            @pessoa.foto_perfil = foto
          end
          conseguiu = true
        rescue
          tentativa += 1
        end
      end

      if !conseguiu
        raise
      end

      # As vezes ele consegue, mas a imagem tem zero bytes
      # Tentar pegar a imagem e vendo se tem zero. Se tiver, tenta mais uma vez

      arquivo_online = open(foto.foto.url)

      if arquivo_online.size == 0
        @pessoa.fotos << foto
        if @pessoa.foto_perfil.blank?
          @pessoa.foto_perfil = foto
        end
      end

      arquivo_online.close

      respond_to do |format|
        if @pessoa.save
          format.js { render 'upload_foto.js.erb' }
        end
      end
    rescue
      respond_to do |format|
        format.js { render 'upload_foto_erro.js.erb' }
      end
    ensure
      File.delete(imagem.filename) if imagem.present? && File.exist?(imagem.filename)
    end
  end

  private

    def salvar_relacoes_ao_confirmar_auto_sugestao pessoa, grupo, conjunto, texto_sugestao, eh_coordenador
      if grupo.present?
        relacao_grupo = RelacaoPessoaGrupo.where({pessoa: pessoa, grupo: grupo}).first

        if relacao_grupo.nil?
          relacao_grupo = RelacaoPessoaGrupo.new({pessoa: pessoa, grupo: grupo})
        end

        if texto_sugestao == 'so_grupo'
          relacao_grupo.eh_coordenador = eh_coordenador
        end

        relacao_grupo.save
      end

      if texto_sugestao != 'so_grupo' && conjunto.present?
        relacao_conjunto = RelacaoPessoaConjunto.where({pessoa: pessoa, conjunto_pessoas: conjunto}).first

        if relacao_conjunto.nil?
          relacao_conjunto = RelacaoPessoaConjunto.new({pessoa: pessoa, conjunto_pessoas: conjunto})
        end

        relacao_conjunto.eh_coordenador = eh_coordenador
        relacao_conjunto.save
      end
    end

    def set_entidades
      if params[:pessoa_id]
        params[:id] = params[:pessoa_id]
      end

      if params[:id]
        begin
          @pessoa = Pessoa.unscoped.find(params[:id])

          if @pessoa.conjuge == nil && @pessoa.conjuge_id != nil
            @pessoa.conjuge = Pessoa.unscoped.find(@pessoa.conjuge_id)
          end
        rescue ActiveRecord::RecordNotFound
          redirect_to root_url and return
        end
      end

      if params[:grupo_id]
        @grupo = Grupo.friendly.find(params[:grupo_id])
      end

      if params[:conjunto_id]
        @conjunto = ConjuntoPessoas.find(params[:conjunto_id])
        @encontro = @conjunto.encontro
        @grupo = @encontro.grupo
      end

      if params[:encontro_id]
        @encontro = Encontro.find(params[:encontro_id])
        @conjunto = @encontro.coordenacao_encontro
        @grupo = @encontro.grupo
      end
    end

    def adicionar_breadcrumbs_entidades
      if eh_auto_inserido || params[:modo] == 'cadastrar_novo'
        return
      end

      if defined?(@grupo)
        if @usuario_logado.eh_super_admin?
          adicionar_breadcrumb "Grupos", grupos_url, "grupos"
        end

        if @usuario_logado.eh_super_admin? ||
          @grupo.coordenadores.include?(@usuario_logado)
          adicionar_breadcrumb @grupo.nome, @grupo, "grupo"
        end
      end

      if defined?(@encontro)
        if @usuario_logado.eh_super_admin? || @grupo.coordenadores.include?(@usuario_logado)
          adicionar_breadcrumb "Encontros", grupo_encontros_path(@grupo), "encontros"
        end

        if @usuario_logado.eh_super_admin? ||
            @grupo.coordenadores.include?(@usuario_logado) ||
            @encontro.coordenadores.include?(@usuario_logado)
          adicionar_breadcrumb @encontro.nome, @encontro, "encontro"
        end
      end

      if defined?(@conjunto)
        if @conjunto.tipo == 'CoordenacaoEncontro'
          adicionar_breadcrumb 'Coordenação', encontro_editar_coordenadores_path(@encontro), "coordenacao"
        elsif @conjunto.tipo == 'Equipe'
          adicionar_breadcrumb "Equipe #{@conjunto.nome}", equipe_path(@conjunto), "equipe"
        else
          adicionar_breadcrumb "#{@conjunto.tipo_do_conjunto} #{@conjunto.nome}", circulo_path(@conjunto), "circulo"
        end
      end

      if @grupo.nil? && @encontro.nil? && @conjunto.nil? && @usuario_logado.eh_super_admin?
        adicionar_breadcrumb "Pessoas", pessoas_url, "pessoas"
      end
    end

    def adicionar_breadcrumb_de_ver_pessoa

      if defined? @encontro
        link = encontro_coordenadores_pessoa_url(@encontro, @pessoa)
      elsif defined? @grupo
        link = grupo_pessoa_url(@grupo, @pessoa)
      else
        link = pessoa_url(@pessoa)
      end

      adicionar_breadcrumb @pessoa.label, link, "ver"
    end

    def pagina_retorno
      if eh_auto_inserido && params[:modo] == 'cadastrar_novo'
        if params.has_key?(:mobile)
          return cadastrar_novo_confirmacao_mobile_path  
        else
          return cadastrar_novo_confirmacao_path
        end
      end

      if params.has_key?(:mobile)
        return mobile_pessoa_path(@pessoa)
      end

      if defined? @conjunto
        if @conjunto.tipo == 'CoordenacaoEncontro'
          return encontro_editar_coordenadores_path(@conjunto.encontro)
        elsif @conjunto.tipo == 'Equipe'
          return equipe_path(@conjunto)
        else
          return circulo_path(@conjunto)
        end
      elsif defined? @grupo
        return grupo_path(@grupo)
      else
        return pessoas_path
      end
    end

    def criar_pessoa(tipo_pessoa)
      if tipo_pessoa == "pessoa"
        pessoa = Pessoa.new(pessoa_params)
      elsif tipo_pessoa == "conjuge"
        pessoa = Pessoa.new(conjuge_params)
      end

      pessoa = atualizar_fotos(pessoa)
      pessoa = atualizar_telefones(pessoa, tipo_pessoa)

      if @usuario_logado.present?
        pessoa.quem_criou = @usuario_logado.id
        pessoa.quem_editou = @usuario_logado.id
      end

      return pessoa
    end

    def atualizar_pessoa(pessoa, tipo_pessoa)
      if tipo_pessoa == "pessoa"
        parametros = pessoa_params
      elsif tipo_pessoa == "conjuge"
        parametros = conjuge_params
      end

      pessoa.assign_attributes(parametros)

      pessoa = atualizar_telefones(pessoa, tipo_pessoa)

      pessoa.auto_inserido = false

      if @usuario_logado.present?
        pessoa.quem_editou = @usuario_logado.id
      end

      return pessoa
    end

    def atualizar_telefones(pessoa, tipo_pessoa)
      telefones = pegar_telefones(params["telefones_#{tipo_pessoa}"], params["operadoras_#{tipo_pessoa}"], params["eh_whatsapps_#{tipo_pessoa}"])

      pessoa.telefones.clear

      pessoa.telefones << telefones

      return pessoa
    end

    def atualizar_relacionamentos(pessoa, tipo_pessoa)
      relacionamentos_a_processar = pessoa.relacionamentos.to_a

      if params.has_key?("relacionamentos_outra_pessoa_id_#{tipo_pessoa}")
        params["relacionamentos_outra_pessoa_id_#{tipo_pessoa}"].each_with_index do |outra_pessoa_id, index|
          padrao_relacionamento_id = params["relacionamentos_padrao_#{tipo_pessoa}"][index]

          outra_pessoa = Pessoa.where(id: outra_pessoa_id).first
          padrao_relacionamento = PadraoRelacionamento.where(id: padrao_relacionamento_id).first
          padrao_relacionamento_oposto = PadraoRelacionamento.where(id: padrao_relacionamento.relacionamento_oposto).first

          if outra_pessoa.present? && padrao_relacionamento.present?
            # checar se ja existe do lado da pessoa
            relacionamento_pessoa = Relacionamento.where(pessoa: pessoa, outra_pessoa: outra_pessoa, padrao_relacionamento: padrao_relacionamento).first
            if relacionamento_pessoa.present?
              # ja existe o relacionamento do lado da pessoa
              # checar se ja existe na outra pessoa
              relacionamento_oposto = Relacionamento.where(pessoa: outra_pessoa, outra_pessoa: pessoa, padrao_relacionamento: padrao_relacionamento_oposto).first
              if relacionamento_oposto.present?
                # nada a fazer, ja tem o relacionamento dos dois lados
              else
                # criar o relacionamento oposto
                relacionamento_oposto = Relacionamento.new({
                  pessoa: outra_pessoa, 
                  outra_pessoa: pessoa, 
                  padrao_relacionamento: padrao_relacionamento_oposto})
                relacionamento_oposto.save
              end
            else
              # nao existe o relacionamento do lado da pessoa, entao vamos criar
              relacionamento_pessoa = Relacionamento.new({
                pessoa: pessoa, 
                outra_pessoa: outra_pessoa, 
                padrao_relacionamento: padrao_relacionamento})
              relacionamento_pessoa.save

              # checar se ja existe na outra pessoa
              relacionamento_oposto = Relacionamento.where(pessoa: outra_pessoa, outra_pessoa: pessoa, padrao_relacionamento: padrao_relacionamento_oposto).first
              if relacionamento_oposto.present?
                # nada a fazer, ja tem o relacionamento dos dois lados
              else
                # criar o relacionamento oposto
                relacionamento_oposto = Relacionamento.new({
                  pessoa: outra_pessoa, 
                  outra_pessoa: pessoa, 
                  padrao_relacionamento: padrao_relacionamento_oposto})
                relacionamento_oposto.save
              end
            end

            relacionamentos_a_processar = remover_relacionamento_do_array(relacionamentos_a_processar, relacionamento_pessoa)
          end
        end
      end

      # deletar os relacionamentos restantes
      if relacionamentos_a_processar.present? && relacionamentos_a_processar.count > 0
        relacionamentos_a_processar.each do |relacionamento_a_deletar|
          outra_pessoa = relacionamento_a_deletar.outra_pessoa
          padrao_relacionamento = relacionamento_a_deletar.padrao_relacionamento
          padrao_relacionamento_oposto = padrao_relacionamento.relacionamento_oposto

          # deletar da outra pessoa
          relacionamento_oposto_a_deletar = Relacionamento.where(pessoa: outra_pessoa, outra_pessoa: pessoa, padrao_relacionamento: padrao_relacionamento).first

          if relacionamento_oposto_a_deletar.present?
            relacionamento_oposto_a_deletar.destroy
          end

          relacionamento_a_deletar.destroy
        end
      end

      return pessoa
    end

    def remover_relacionamento_do_array(array, relacionamento_a_remover)
      array.each do |elemento|
        if elemento.pessoa == relacionamento_a_remover.pessoa && 
          elemento.outra_pessoa == relacionamento_a_remover.outra_pessoa && 
          elemento.padrao_relacionamento == relacionamento_a_remover.padrao_relacionamento
          array.delete(elemento)
          break
        end
      end

      return array
    end

    def atualizar_fotos(pessoa)
      if pessoa.fotos.size < 3 && pessoa.url_imagem_facebook.present?
        nome_do_arquivo = URI::split(pessoa.url_imagem_facebook)[5].split("/").last
        ja_tem_essa_foto = false
        pessoa.fotos.each do |foto|
          if foto.foto_file_name == nome_do_arquivo
            ja_tem_essa_foto = true
            break
          end
        end

        if !ja_tem_essa_foto
          foto = Foto.new
          foto.foto = open(pessoa.url_imagem_facebook)
          foto.foto_file_name = nome_do_arquivo
          if pessoa.foto_perfil.blank?
            pessoa.foto_perfil = foto
            pessoa.save
          end
          pessoa.fotos << foto
        end
      end

      return pessoa
    end

    def remover_facebook_se_necessario(pessoa, tinha_antes)
      if tinha_antes && (pessoa.tem_facebook.nil? || pessoa.tem_facebook == "off")
        pessoa.url_facebook = nil
        pessoa.url_imagem_facebook = nil
      end

      return pessoa
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pessoa_params
      if params[:url_facebook_pessoa].present? && params[:usuario_facebook_pessoa].blank?
        informacoes = pegar_informacoes_facebook(params[:url_facebook_pessoa])
        if informacoes[:imagem_grande].present?
          params[:url_imagem_facebook_pessoa] = informacoes[:imagem_grande]
        end
        if informacoes[:usuario].present?
          params[:usuario_facebook_pessoa] = informacoes[:usuario]
        end
      end

      instrumentos = pegar_instrumentos(params[:instrumentos_pessoa])

      hash = ActionController::Parameters.new({nome: (params[:nome_pessoa] || "").strip,
                                              nome_usual: (params[:nome_usual_pessoa] || "").strip,
                                              dia: params[:dia_pessoa],
                                              mes: params[:mes_pessoa],
                                              ano: params[:ano_pessoa],
                                              eh_homem: params[:eh_homem_pessoa],
                                              email: (params[:email_pessoa] || "").downcase.strip,
                                              rua: (params[:rua_pessoa] || "").strip,
                                              numero: (params[:numero_pessoa] || "").strip,
                                              bairro: (params[:bairro_pessoa] || "").strip,
                                              cidade: (params[:cidade_pessoa] || "").strip,
                                              estado: params[:estado_pessoa],
                                              cep: (params[:cep_pessoa] || "").strip,
                                              tem_facebook: params[:tem_facebook_pessoa],
                                              usuario_facebook: params[:usuario_facebook_pessoa],
                                              id_app_facebook: params[:id_app_facebook_pessoa],
                                              url_facebook: params[:url_facebook_pessoa].strip,
                                              url_imagem_facebook: params[:url_imagem_facebook_pessoa],
                                              instrumentos: instrumentos, 
                                              onde_fez_alteracao: params[:onde_fez_alteracao]})
      hash.permit!
      return hash
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def conjuge_params
      if params[:url_facebook_conjuge].present? && params[:usuario_facebook_conjuge].blank?
        informacoes = pegar_informacoes_facebook(params[:url_facebook_conjuge])
        if informacoes[:imagem_grande].present?
          params[:url_imagem_facebook_conjuge] = informacoes[:imagem_grande]
        end
        if informacoes[:usuario].present?
          params[:usuario_facebook_conjuge] = informacoes[:usuario]
        end
      end

      instrumentos = pegar_instrumentos(params[:instrumentos_conjuge])

      hash = ActionController::Parameters.new(nome: (params[:nome_conjuge] || "").strip,
                                              nome_usual: (params[:nome_usual_conjuge] || "").strip,
                                              dia: params[:dia_conjuge],
                                              mes: params[:mes_conjuge],
                                              ano: params[:ano_conjuge],
                                              eh_homem: params[:eh_homem_conjuge],
                                              email: (params[:email_conjuge] || "").downcase.strip,
                                              tem_facebook: params[:tem_facebook_conjuge],
                                              usuario_facebook: params[:usuario_facebook_conjuge].gsub(/\s+/, " ").strip,
                                              id_app_facebook: params[:id_app_facebook_conjuge],
                                              url_facebook: params[:url_facebook_conjuge].strip,
                                              url_imagem_facebook: params[:url_imagem_facebook_conjuge],
                                              instrumentos: instrumentos, 
                                              onde_fez_alteracao: params[:onde_fez_alteracao])
      hash.permit!
      return hash
    end

    def pegar_telefones(numeros, operadoras, eh_whatsapps)
      telefones = []

      if numeros.present? && operadoras.present?
        numeros.each_with_index do |numero_telefone, index|
          operadora = operadoras[index]
          eh_whatsapp = eh_whatsapps[index] == "true"

          if numero_telefone.present? && operadora.present?
            telefones << Telefone.new(telefone: numero_telefone.strip, operadora: operadora, eh_whatsapp: eh_whatsapp)
          end
        end
      end

      return telefones
    end

    def pegar_instrumentos(nomes_instrumentos)
      instrumentos = []

      if nomes_instrumentos.present?
        nomes_instrumentos.uniq.each do |nome_instrumento|
          instrumentos << Instrumento.new(nome: nome_instrumento)
        end
      end

      return instrumentos
    end

    def criar_relacoes_auto_inserir()
      ['pessoa', 'conjuge', 'casal'].each do |tipo_pessoa|
        if tipo_pessoa == 'casal'
          pessoa = @pessoa
          conjuge = @conjuge
        else
          pessoa = instance_variable_get("@#{tipo_pessoa}")
          conjuge = nil
        end

        grupos = instance_variable_get("@grupos_auto_inserir_#{tipo_pessoa}")
        coordenadores = instance_variable_get("@coordenadores_auto_inserir_#{tipo_pessoa}")
        encontros = instance_variable_get("@encontros_auto_inserir_#{tipo_pessoa}")
        sugestoes = instance_variable_get("@sugestoes_auto_inserir_#{tipo_pessoa}")
        conjuntos = instance_variable_get("@conjuntos_auto_inserir_#{tipo_pessoa}")
        eh_auto_inseridos = instance_variable_get("@eh_auto_inseridos_#{tipo_pessoa}")

        if grupos.present?
          grupos.each_with_index do |grupo_id, indice|
            eh_coordenador = coordenadores[indice] == "true"
            texto_sugestao = sugestoes[indice]
            encontro_id = encontros[indice]
            esse_eh_auto_inserido = eh_auto_inseridos[indice] == "true"

            if esse_eh_auto_inserido
              if texto_sugestao != ''
                auto_sugestao = nil
                if texto_sugestao == 'so_grupo'
                  auto_sugestao = AutoSugestao.where({pessoa: pessoa, conjuge: conjuge, grupo_id: grupo_id}).first
                end

                if auto_sugestao.nil?
                  auto_sugestao = AutoSugestao.new({pessoa: pessoa, conjuge: conjuge, grupo_id: grupo_id})
                end

                if encontro_id != "-1"
                  auto_sugestao.encontro_id = encontro_id
                end

                auto_sugestao.sugestao = texto_sugestao
                auto_sugestao.coordenador = eh_coordenador

                auto_sugestao.save
              end
            else
              conjunto_id = conjuntos[indice]

              if conjunto_id.present? && conjunto_id != "-1"
                conjunto = ConjuntoPessoas.find(conjunto_id)
              end

              if grupo_id.present?
                grupo = Grupo.find(grupo_id)
              end

              os_dois = tipo_pessoa == 'casal'

              if texto_sugestao == 'so_grupo' && grupo.present?
                salvar_relacao_grupo(pessoa, grupo, os_dois, eh_coordenador)
              elsif conjunto.present? 
                salvar_relacao_conjunto(pessoa, conjunto, os_dois, eh_coordenador)
              end

            end
          end
        end
      end
    end

    def precisa_poder_editar_pessoa pessoa
      if !@usuario_logado.permissoes.pode_editar_pessoa(pessoa)
        redirect_to root_url and return
      end
    end

    def precisa_poder_ver_pessoa pessoa
      if pessoa.conjuge.present?
        if !@usuario_logado.permissoes.pode_ver_pessoa(pessoa) && !@usuario_logado.permissoes.pode_ver_pessoa(pessoa.conjuge)
          redirect_to root_url and return
        end
      else
        if !@usuario_logado.permissoes.pode_ver_pessoa(pessoa)
          redirect_to root_url and return
        end
      end
    end

    def precisa_poder_pesquisar_pessoas
      if !@usuario_logado.permissoes.pode_pesquisar_pessoas
        redirect_to root_url and return
      end
    end

    def precisa_poder_criar_pessoas
      if params[:conjunto_id] || params[:encontro_id]
        if params.has_key?(:encontro_id)
          conjunto = Encontro.find(params[:encontro_id]).coordenacao_encontro
        else
          conjunto = ConjuntoPessoas.find(params[:conjunto_id])
        end

        if !@usuario_logado.permissoes.pode_criar_pessoas_em_conjunto(conjunto)
          redirect_to root_url and return
        end
      elsif params[:grupo_id]
        if !@usuario_logado.permissoes.pode_criar_pessoas_em_grupo(params[:grupo_id])
          redirect_to root_url and return
        end
      else
        if !@usuario_logado.eh_super_admin?
          redirect_to root_url and return
        end
      end
    end

    def precisa_poder_confirmar_ou_rejeitar_auto_sugestao(auto_sugestao)
      if !@usuario_logado.permissoes.pode_confirmar_ou_rejeitar_auto_sugestao(auto_sugestao)
        redirect_to root_url and return
      end
    end

    def salvar_relacao_grupo pessoa, grupo, os_dois, eh_coordenador
      relacao_pessoa = RelacaoPessoaGrupo.where({:pessoa_id => pessoa.id, :grupo_id => grupo.id}).first

      if relacao_pessoa.nil?
        relacao_pessoa = RelacaoPessoaGrupo.new({:pessoa_id => pessoa.id, :grupo_id => grupo.id})
      end

      relacao_pessoa.eh_coordenador = eh_coordenador
      relacao_pessoa.save

      if pessoa.conjuge.present? && os_dois
        relacao_conjuge = RelacaoPessoaGrupo.where({:pessoa_id => pessoa.conjuge.id, :grupo_id => grupo.id}).first

        if relacao_conjuge.nil?
          relacao_conjuge = RelacaoPessoaGrupo.new({:pessoa_id => pessoa.conjuge.id, :grupo_id => grupo.id})
        end

        relacao_conjuge.eh_coordenador = eh_coordenador
        relacao_conjuge.save
      end
    end

    def salvar_relacao_conjunto pessoa, conjunto, os_dois, eh_coordenador
      relacao_pessoa = RelacaoPessoaConjunto.where({:pessoa_id => pessoa.id, :conjunto_pessoas_id => conjunto.id}).first

      if relacao_pessoa.nil?
        relacao_pessoa = RelacaoPessoaConjunto.new({:pessoa_id => pessoa.id, :conjunto_pessoas_id => conjunto.id})
        relacao_pessoa.eh_coordenador = eh_coordenador
        relacao_pessoa.save
      end

      if pessoa.conjuge.present? && os_dois
        relacao_conjuge = RelacaoPessoaConjunto.where({:pessoa_id => pessoa.conjuge.id, :conjunto_pessoas_id => conjunto.id}).first

        if relacao_conjuge.nil?
          relacao_conjuge = RelacaoPessoaConjunto.new({:pessoa_id => pessoa.conjuge.id, :conjunto_pessoas_id => conjunto.id})
          relacao_conjuge.eh_coordenador = eh_coordenador
          relacao_conjuge.save
        end
      end

      salvar_relacao_grupo(pessoa, conjunto.encontro.grupo, os_dois, false)
    end

    def setar_variaveis_auto_inserido
      if eh_auto_inserido && params[:modo] == 'cadastrar_novo'
        @pessoa.auto_inserido = true
        if @eh_casal
          @conjuge.auto_inserido = true
        end
      end

      if params[:grupos_auto_inserir_pessoa]
        @grupos_auto_inserir_pessoa = params[:grupos_auto_inserir_pessoa].select{|item| item != '-1' && item != ''}
        if @eh_casal
          @grupos_auto_inserir_conjuge = params[:grupos_auto_inserir_conjuge].select{|item| item != '-1' && item != ''}
        end
      end

      @encontros_auto_inserir_pessoa = params[:encontros_auto_inserir_pessoa]
      @sugestoes_auto_inserir_pessoa = params[:sugestoes_auto_inserir_pessoa]
      @coordenadores_auto_inserir_pessoa = params[:coordenadores_auto_inserir_pessoa]
      @conjuntos_auto_inserir_pessoa = params[:conjuntos_auto_inserir_pessoa]
      @eh_auto_inseridos_pessoa = params[:auto_inserido_pessoa]

      if eh_auto_inserido && 
        ((@grupos_auto_inserir_pessoa.nil? || @grupos_auto_inserir_pessoa.count == 0 ||
        @sugestoes_auto_inserir_pessoa.select{|item| !item.empty?}.count == 0) && 
        !@eh_casal)
        @pessoa.errors[:auto_inserir] = 'É obrigatório inserir ao menos uma participação'
        @pessoa_valida = false
      end

      if @eh_casal
        if params[:grupos_auto_inserir_conjuge]
          @grupos_auto_inserir_conjuge = params[:grupos_auto_inserir_conjuge].select{|item| item != '-1' && item != ''}
        end

        @encontros_auto_inserir_conjuge = params[:encontros_auto_inserir_conjuge]
        @sugestoes_auto_inserir_conjuge = params[:sugestoes_auto_inserir_conjuge]
        @coordenadores_auto_inserir_conjuge = params[:coordenadores_auto_inserir_conjuge]
        @conjuntos_auto_inserir_conjuge = params[:conjuntos_auto_inserir_conjuge]
        @eh_auto_inseridos_conjuge = params[:auto_inserido_conjuge]

        if params[:grupos_auto_inserir_casal]
          @grupos_auto_inserir_casal = params[:grupos_auto_inserir_casal].select{|item| item != '-1' && item != ''}
        end

        @encontros_auto_inserir_casal = params[:encontros_auto_inserir_casal]
        @sugestoes_auto_inserir_casal = params[:sugestoes_auto_inserir_casal]
        @coordenadores_auto_inserir_casal = params[:coordenadores_auto_inserir_casal]
        @conjuntos_auto_inserir_casal = params[:conjuntos_auto_inserir_casal]
        @eh_auto_inseridos_casal = params[:auto_inserido_casal]

        if eh_auto_inserido && 
          ((@grupos_auto_inserir_pessoa.nil? || @grupos_auto_inserir_pessoa.count == 0 ||
            @sugestoes_auto_inserir_pessoa.select{|item| !item.empty?}.count == 0) && 
            (@grupos_auto_inserir_conjuge.nil? || @grupos_auto_inserir_conjuge.count == 0 ||
            @sugestoes_auto_inserir_conjuge.select{|item| !item.empty?}.count == 0) && 
            (@grupos_auto_inserir_casal.nil? || @grupos_auto_inserir_casal.count == 0 ||
              @sugestoes_auto_inserir_casal.select{|item| !item.empty?}.count == 0))
          @pessoa.errors[:auto_inserir] = 'É obrigatório inserir ao menos uma participação'
          @conjuge_valido = false
        end
      end

    end

    def eh_auto_inserido
      return params[:modo] == 'cadastrar_novo'
    end



end
