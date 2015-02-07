#encoding: utf-8
require "open-uri"

class PessoasController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => [:cadastrar_novo, :create, :cadastrar_novo_confirmacao]
  before_action :set_entidades, :adicionar_breadcrumbs_entidades
  skip_before_action :adicionar_breadcrumbs_entidades, only: [:cadastrar_novo, :cadastrar_novo_confirmacao]
  skip_before_action :verify_authenticity_token, only: [:lista_pessoas_js]

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

    @participacoes = (@pessoa.conjuntos_permanentes + @pessoa.equipes).select{|c| pode_ver_participacao(c, @pessoa)}

    if @pessoa.conjuge.present?
      @participacoes_conjuge = (@pessoa.conjuge.conjuntos_permanentes + @pessoa.conjuge.equipes).select{|c| pode_ver_participacao(c, @pessoa.conjuge)}
    end
    
    @participacoes = @participacoes.sort_by!{|c| c.encontro.data_inicio}.reverse
  end

  # GET /pessoas/new
  def new
    precisa_poder_criar_pessoas
    return if performed?

    adicionar_breadcrumb "Criar nova pessoa", new_pessoa_url, "criar"

    @pessoa = Pessoa.new
    @conjuge = Pessoa.new
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

  end

  # POST /pessoas
  # POST /pessoas.json
  def create
    if !params.has_key?(:auto_inserido)
      precisa_poder_criar_pessoas
      return if performed?
    end

    adicionar_breadcrumb "Criar nova pessoa", new_pessoa_url, "criar"

    @pessoa = criar_pessoa("pessoa")

    @foto_grande_pessoa = params[:imagem_facebook_pessoa]
    @foto_grande_conjuge = params[:imagem_facebook_conjuge]

    pessoa_valida = @pessoa.valid?

    if params.has_key?(:auto_inserido)
      @pessoa.auto_inserido = true

      if params[:grupos_auto_inserir_pessoa]
        @grupos_auto_inserir_pessoa = params[:grupos_auto_inserir_pessoa].select{|item| item != '-1' && item != ''}
      end
      @encontros_auto_inserir_pessoa = params[:encontros_auto_inserir_pessoa]
      @sugestoes_auto_inserir_pessoa = params[:sugestoes_auto_inserir_pessoa]
      @coordenadores_auto_inserir_pessoa = params[:coordenadores_auto_inserir_pessoa]

      if @grupos_auto_inserir_pessoa.nil? || @grupos_auto_inserir_pessoa.count == 0 ||
        @sugestoes_auto_inserir_pessoa.select{|item| !item.empty?}.count == 0
        @pessoa.errors[:auto_inserir] = 'É obrigatório inserir ao menos uma participação'
        pessoa_valida = false
      end
    end

    @eh_casal = params[:casado_ou_solteiro] == 'casado'

    if @eh_casal
      msg_sucesso = "Casal criado com sucesso"

      @tipo_conjuge = params[:tipo_de_conjuge_escolhido]

      if @tipo_conjuge == "ja_cadastrado" && !params[:id_conjuge].blank?
        @conjuge = Pessoa.find(params[:id_conjuge])
        @tipo_conjuge = 'ja_cadastrado'
      else
        @conjuge = criar_pessoa("conjuge")
        @tipo_conjuge = 'form'
      end

      if pessoa_valida
        @conjuge.rua = @pessoa.rua
        @conjuge.numero = @pessoa.numero
        @conjuge.bairro = @pessoa.bairro
        @conjuge.cidade = @pessoa.cidade
        @conjuge.estado = @pessoa.estado
        @conjuge.cep = @pessoa.cep
      end

      conjuge_valido = @conjuge.valid?

      if params.has_key?(:auto_inserido)
        @conjuge.auto_inserido = true

        if params[:grupos_auto_inserir_conjuge]
          @grupos_auto_inserir_conjuge = params[:grupos_auto_inserir_conjuge].select{|item| item != '-1' && item != ''}
        end
        @encontros_auto_inserir_conjuge = params[:encontros_auto_inserir_conjuge]
        @sugestoes_auto_inserir_conjuge = params[:sugestoes_auto_inserir_conjuge]
        @coordenadores_auto_inserir_conjuge = params[:coordenadores_auto_inserir_conjuge]

        if @grupos_auto_inserir_conjuge.nil? || @grupos_auto_inserir_conjuge.count == 0 ||
            @sugestoes_auto_inserir_conjuge.select{|item| !item.empty?}.count == 0
          @conjuge.errors[:auto_inserir] = 'É obrigatório inserir ao menos uma participação'
          conjuge_valido = false
        end
      end

      casal_valido = pessoa_valida && conjuge_valido

      if casal_valido
        @pessoa.conjuge = @conjuge
        @conjuge.conjuge = @pessoa
      end
    else
      msg_sucesso = "Pessoa criada com sucesso"
      @conjuge = Pessoa.new
    end

    respond_to do |format|
      if (@eh_casal && casal_valido && @pessoa.save && @conjuge.save) ||
        (!@eh_casal && pessoa_valida && @pessoa.save)

        if params.has_key?(:auto_inserido)
          criar_relacoes_auto_inserir
        end

        if defined? @conjunto
          if @conjunto.tipo == 'CoordenacaoEncontro'
            texto_adicionado = "à coordenação do encontro #{@conjunto.encontro.nome} e ao grupo #{@conjunto.encontro.grupo.nome}"
          elsif @conjunto.tipo == 'Equipe'
            texto_adicionado = "à equipe #{@conjunto.nome} do encontro #{@conjunto.encontro.nome} e ao grupo #{@conjunto.encontro.grupo.nome}"
          else
            texto_adicionado = "a #{@conjunto.tipo_do_conjunto} #{@conjunto.nome} do encontro #{@conjunto.encontro.nome} e ao grupo #{@conjunto.encontro.grupo.nome}"
          end

          salvar_relacao_conjunto(@pessoa, @grupo)

          if @eh_casal
            msg_sucesso = "Casal criado e adicionado #{texto_adicionado} com sucesso"
          else
            msg_sucesso = "Pessoa criada e adicionada #{texto_adicionado} com sucesso"
          end

        elsif defined? @grupo

          salvar_relacao_grupo(@pessoa, @grupo)
          if @eh_casal
            msg_sucesso = "Casal criado e adicionado ao grupo #{@grupo.nome} com sucesso"
          else
            msg_sucesso = "Pessoa criada e adicionada ao grupo #{@grupo.nome} com sucesso"
          end

        end

        format.html { redirect_to pagina_retorno, notice: msg_sucesso }
        format.json { render action: 'show', status: :created, location: @pessoa }
      else
        if params.has_key?(:auto_inserido)
          format.html { render action: 'cadastrar_novo' }
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

    @foto_grande_pessoa = params[:imagem_facebook_pessoa]
    @foto_grande_conjuge = params[:imagem_facebook_conjuge]

    precisa_salvar_pessoa = true
    precisa_salvar_velho_conjuge = false
    precisa_salvar_conjuge = false

    @eh_casal = params[:casado_ou_solteiro] == 'casado'

    if @eh_casal
      precisa_salvar_conjuge = true

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
      if ((precisa_salvar_pessoa && @pessoa.save) || !precisa_salvar_pessoa) &&
          ((precisa_salvar_conjuge && @conjuge.save) || !precisa_salvar_conjuge) &&
          ((precisa_salvar_velho_conjuge && @velho_conjuge.save) || !precisa_salvar_velho_conjuge)
        if defined? @conjunto
          salvar_relacao_conjunto(@pessoa, @conjunto)
        elsif defined? @grupo
          salvar_relacao_grupo(@pessoa, @grupo)
        end
        format.html { redirect_to pagina_retorno, notice: msg_sucesso }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @pessoa.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pessoas/1
  # DELETE /pessoas/1.json
  def destroy
    if pode_excluir_pessoa @pessoa
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
    pessoa = Pessoa.unscoped.where(email_facebook: session[:email_facebook])

    if pessoa.count > 0
      redirect_to cadastrar_novo_confirmacao_url and return
    end

    @pessoa = Pessoa.new
    @pessoa.eh_homem = session[:eh_homem]
    @pessoa.nome_facebook = session[:nome_facebook]
    @pessoa.email_facebook = session[:email_facebook]
    @pessoa.url_facebook = session[:url_facebook]

    @foto_grande_pessoa = session[:url_foto_grande]
    @foto_pequena_pessoa = session[:url_foto_pequena]

    if session[:casado]
      @eh_casal = true

      if session[:id_usuario_conjuge]
        @tipo_conjuge = 'ja_cadastrado'
        @conjuge = Pessoa.where(session[:id_usuario_conjuge])
      else
        @tipo_conjuge = 'form'

        @conjuge = Pessoa.new
        @conjuge.eh_homem = session[:eh_homem_conjuge]
        @conjuge.foto_grande = open(session[:url_foto_grande_conjuge])
        @conjuge.foto_pequena = open(session[:url_foto_pequena_conjuge])
        @conjuge.nome_facebook = session[:nome_facebook_conjuge]
        @conjuge.email_facebook = session[:email_facebook_conjuge]
        @conjuge.url_facebook = session[:url_facebook_conjuge]

        @foto_grande_conjuge = session[:url_foto_grande_conjuge]
        @foto_pequena_conjuge = session[:url_foto_pequena_conjuge]
      end

      @pessoa.conjuge = @conjuge
    else
      @eh_casal = false
      @tipo_conjuge = 'form'
      @conjuge = Pessoa.new
      @conjuge.eh_homem = !@pessoa.eh_homem
    end
  end

  def cadastrar_novo_confirmacao
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

        if pessoa.conjuge.foto_grande.present?
          conjuge = conjuge.merge({url_foto_grande: pessoa.conjuge.foto_grande.url})
        end

        if pessoa.conjuge.foto_pequena.present?
          conjuge = conjuge.merge({url_foto_pequena: pessoa.conjuge.foto_pequena.url})
        end
      else
        conjuge = nil
      end

      pessoa_hash = pessoa.attributes

      if pessoa.foto_grande.present?
        pessoa_hash = pessoa_hash.merge({url_foto_grande: pessoa.foto_grande.url})
      end

      if pessoa.foto_pequena.present?
        pessoa_hash = pessoa_hash.merge({url_foto_pequena: pessoa.foto_pequena.url})
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

    @pessoas = Pessoa.pegar_pessoas(session[:id_pessoas])

    @total = @pessoas.count
    @numero_casais = @pessoas.select{|p| p.conjuge != nil}.count / 2

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

    @tipo_pagina = params[:tipo_pagina]

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

      pessoas = Pessoa.pegar_pessoas(session[:id_pessoas_antes_do_filtro])

      query = ActiveSupport::Inflector.transliterate(params[:query].downcase)

      if pessoas && query && query.length >= 3
        session[:id_pessoas] = pessoas.select{|pessoa| ActiveSupport::Inflector.transliterate(pessoa.nome.downcase).include?(query) ||
            ActiveSupport::Inflector.transliterate(pessoa.nome_usual.downcase).include?(query)}
          .collect{|pessoa| pessoa.id}
      end
    end

    render text: 'ok'
  end

  def confirmar_auto_sugestao
    auto_sugestao = AutoSugestao.find(params[:id_auto_sugestao])

    pessoa = Pessoa.unscoped.find(auto_sugestao.pessoa_id)

    grupo = auto_sugestao.grupo
    if grupo.present?
      relacao_grupo = RelacaoPessoaGrupo.where({pessoa: pessoa, grupo: grupo}).first

      if relacao_grupo.nil?
        relacao_grupo = RelacaoPessoaGrupo.new({pessoa: pessoa, grupo: grupo})
      end

      if auto_sugestao.sugestao == 'so_grupo'
        relacao_grupo.eh_coordenador = params[:eh_coordenador] == "true"
      end

      relacao_grupo.save
    end

    if auto_sugestao.sugestao != 'so_grupo' && params[:id_conjunto]
      conjunto = ConjuntoPessoas.find(params[:id_conjunto])

      if conjunto.present?
        relacao_conjunto = RelacaoPessoaConjunto.where({pessoa: pessoa, conjunto_pessoas: conjunto}).first

        if relacao_conjunto.nil?
          relacao_conjunto = RelacaoPessoaConjunto.new({pessoa: pessoa, conjunto_pessoas: conjunto})
        end

        relacao_conjunto.eh_coordenador = params[:eh_coordenador] == "true"
        relacao_conjunto.save
      end
    end

    if pessoa.auto_inserido
      pessoa.auto_inserido = false
      pessoa.save
    end

    auto_sugestao.destroy

    render text: 'ok'
  end

  def rejeitar_auto_sugestao
    auto_sugestao = AutoSugestao.find(params[:id_auto_sugestao])

    pessoa = Pessoa.unscoped.find(auto_sugestao.pessoa_id)

    auto_sugestao.destroy

    if pessoa.auto_inserido && pessoa.auto_sugestoes.count == 0
      pessoa.destroy
    end

    render text: 'ok'
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
      @parametros_pesquisa_pessoas.submeteu = true

      pesquisar_em_grupos = false
      pesquisar_em_instrumentos = false
      pesquisar_em_conjuntos = false
      pesquisar_recomendacoes_do_coordenador_permanente = false
      pesquisar_recomendacoes_equipes = false

      filtros_total = []

      filtros_pessoas = []

      if params[:nome].present?
        @parametros_pesquisa_pessoas.nome = params[:nome]
        filtros_pessoas << "(pessoas.nome LIKE '%#{@parametros_pesquisa_pessoas.nome}%' OR pessoas.nome_usual LIKE '%#{@parametros_pesquisa_pessoas.nome}%')"
      end

      if params[:generos].present?
        @parametros_pesquisa_pessoas.generos = params[:generos]
        if @parametros_pesquisa_pessoas.generos.count == 1
          filtros_pessoas << "pessoas.eh_homem = #{@parametros_pesquisa_pessoas.generos[0] == 'homem'}"
        end
      end

      if params[:estados_civis].present?
        @parametros_pesquisa_pessoas.estados_civis = params[:estados_civis]
        if @parametros_pesquisa_pessoas.estados_civis.count == 1
          filtros_pessoas << "pessoas.conjuge_id IS #{@parametros_pesquisa_pessoas.estados_civis[0] == 'casado' ? 'NOT ' : ''}NULL"
        end
      end

      if filtros_pessoas.count > 0
        filtros_total << "(#{filtros_pessoas.join(" AND ")})"
      end

      if params[:instrumentos].present?
        @parametros_pesquisa_pessoas.instrumentos = params[:instrumentos]
        filtros_instrumentos = []
        params[:instrumentos].each do |instrumento|
          filtros_instrumentos << "instrumentos.nome LIKE '%#{instrumento}%'"
        end
        filtros_total << "(#{filtros_instrumentos.join(" OR ")})"
        pesquisar_em_instrumentos = true
      end

      if params[:grupos]
        pesquisar_em_grupos = true
        @parametros_pesquisa_pessoas.grupos = params[:grupos]
        filtros_total << "(grupos.id IN (#{params[:grupos].join(", ")}))"
      else
        unless @usuario_logado.eh_super_admin?
          pesquisar_em_grupos = true
          filtros_total << "(grupos.id IN (#{@usuario_logado.grupos_que_pode_pesquisar.collect{|g| g.id}.join(", ")}))"
        end
      end

      if params[:equipes]
        @parametros_pesquisa_pessoas.equipes = params[:equipes]

        pesquisar_em_conjuntos = true

        filtros_equipes = []

        params[:equipes].each do |equipe_procurando|
          partes = equipe_procurando.split("###")
          equipe = partes.first
          grupo = partes.last

          if equipe == 'coordPerm'
            filtros_equipes << "(conjuntos_pessoas.tipo = 'ConjuntoPermanente' AND relacoes_pessoa_conjunto.eh_coordenador = true AND grupos.id = #{grupo})"
            pesquisar_em_grupos = true
          else
            filtros_equipes << "(conjuntos_pessoas.equipe_padrao_relacionada = #{equipe})"
          end
        end
        filtros_total << "(#{filtros_equipes.join(" OR ")})"
      end

      if params[:recomendacoes]
        @parametros_pesquisa_pessoas.recomendacoes = params[:recomendacoes]

        filtros_recomendacoes = []

        params[:recomendacoes].each do |recomendacao_procurando|
          partes = recomendacao_procurando.split("###")
          equipe = partes.first
          grupo = partes.last

          if equipe == 'coordPerm'
            filtros_recomendacoes << "(recomendacoes_do_coordenador_permanente.recomenda_pra_coordenador = true AND recomendacoes_do_coordenador_permanente.conjunto_pessoas_id = conjuntos_pessoas.id AND conjuntos_pessoas.encontro_id = encontros.id AND encontros.grupo_id = #{grupo})"
            pesquisar_recomendacoes_do_coordenador_permanente = true
          else
            filtros_recomendacoes << "(recomendacoes_equipes.conjunto_pessoas_id = #{equipe})"
            pesquisar_recomendacoes_equipes = true
          end
        end

        filtros_total << "(#{filtros_recomendacoes.join(" OR ")})"
      end

      objetos = Pessoa

      if pesquisar_em_grupos
        objetos = objetos.joins(:grupos)
      end

      if pesquisar_em_instrumentos
        objetos = objetos.joins(:instrumentos)
      end

      if pesquisar_recomendacoes_do_coordenador_permanente
        objetos = objetos.joins(:recomendacao_do_coordenador_permanente)
          .joins('INNER JOIN conjuntos_pessoas ON recomendacoes_do_coordenador_permanente.conjunto_pessoas_id = conjuntos_pessoas.id')
          .joins('INNER JOIN encontros ON conjuntos_pessoas.encontro_id = encontros.id')
      end

      if pesquisar_em_conjuntos && !pesquisar_recomendacoes_do_coordenador_permanente
        objetos = objetos.joins(:conjuntos_pessoas)
      end

      if pesquisar_recomendacoes_equipes
        objetos = objetos.joins(:recomendacoes_equipes)
      end

      debugger

      pessoas = objetos.where(filtros_total.join(" AND ")).distinct

      carregar_pessoas(pessoas)
    end

  end

  private
    def set_entidades
      if params[:id]
        begin
          @pessoa = Pessoa.unscoped.find(params[:id])
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
      if params.has_key?(:auto_inserido)
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
      if params.has_key?(:auto_inserido)
        return cadastrar_novo_confirmacao_path
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

      pessoa = atualizar_fotos(pessoa, tipo_pessoa)

      return pessoa
    end

    def atualizar_pessoa(pessoa, tipo_pessoa)
      if tipo_pessoa == "pessoa"
        pessoa.assign_attributes(pessoa_params)
      elsif tipo_pessoa == "conjuge"
        pessoa.assign_attributes(conjuge_params)
      end

      pessoa = atualizar_fotos(pessoa, tipo_pessoa)

      return pessoa
    end

    def atualizar_fotos(pessoa, tipo_pessoa)
      if tipo_pessoa == "pessoa"
        param_foto_grande = "imagem_facebook_pessoa"
        param_foto_pequena = "url_foto_pequena_pessoa"
      elsif tipo_pessoa == "conjuge"
        param_foto_grande = "imagem_facebook_conjuge"
        param_foto_pequena = "url_foto_pequena_conjuge"
      end

      if params[param_foto_grande].present?
        nome_do_arquivo = URI::split(params[param_foto_grande])[5].split("/").last
        if pessoa.foto_grande_file_name != nome_do_arquivo
          begin
            pessoa.foto_grande = open(params[param_foto_grande])
          rescue
          end
          pessoa.foto_grande_file_name = nome_do_arquivo
        end
      else
        pessoa.foto_grande.clear
      end

      if params[param_foto_pequena].present?
        nome_do_arquivo = URI::split(params[param_foto_pequena])[5].split("/").last
        if pessoa.foto_pequena_file_name != nome_do_arquivo
          begin
            foto_pequena = open(params[param_foto_pequena])
          rescue
          end
          foto_pequena_file_name = nome_do_arquivo
        end
      else
        pessoa.foto_pequena.clear
      end

      return pessoa
    end

    def remover_facebook_se_necessario(pessoa, tinha_antes)
      if tinha_antes && (pessoa.tem_facebook.nil? || pessoa.tem_facebook == "off")
        pessoa.nome_facebook = nil
        pessoa.url_facebook = nil
        pessoa.email_facebook = nil
        pessoa.url_imagem_facebook = nil
      end

      return pessoa
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pessoa_params
      if params[:cep1_pessoa].present? || params[:cep2_pessoa].present?
        cep = "#{params[:cep1_pessoa]}-#{params[:cep2_pessoa]}"
      end

      telefones = pegar_telefones(params[:telefones_pessoa], params[:operadoras_pessoa])
      instrumentos = pegar_instrumentos(params[:instrumentos_pessoa])

      hash = ActionController::Parameters.new({nome: params[:nome_pessoa],
                                              nome_usual: params[:nome_usual_pessoa],
                                              dia: params[:dia_pessoa],
                                              mes: params[:mes_pessoa],
                                              ano: params[:ano_pessoa],
                                              eh_homem: params[:eh_homem_pessoa],
                                              email: params[:email_pessoa],
                                              rua: params[:rua_pessoa],
                                              numero: params[:numero_pessoa],
                                              bairro: params[:bairro_pessoa],
                                              cidade: params[:cidade_pessoa],
                                              estado: params[:estado_pessoa],
                                              cep: cep,
                                              tem_facebook: params[:tem_facebook_pessoa],
                                              nome_facebook: params[:nome_facebook_pessoa].gsub(/\s+/, " ").strip,
                                              email_facebook: params[:email_facebook_pessoa],
                                              url_facebook: params[:url_facebook_pessoa].strip.split("?")[0],
                                              url_imagem_facebook: params[:imagem_facebook_pessoa].strip,
                                              telefones: telefones,
                                              instrumentos: instrumentos})
      hash.permit!
      return hash
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def conjuge_params
      telefones = pegar_telefones(params[:telefones_conjuge], params[:operadoras_conjuge])
      instrumentos = pegar_instrumentos(params[:instrumentos_conjuge])

      hash = ActionController::Parameters.new(nome: params[:nome_conjuge],
                                              nome_usual: params[:nome_usual_conjuge],
                                              dia: params[:dia_conjuge],
                                              mes: params[:mes_conjuge],
                                              ano: params[:ano_conjuge],
                                              eh_homem: params[:eh_homem_conjuge],
                                              email: params[:email_conjuge],
                                              tem_facebook: params[:tem_facebook_conjuge],
                                              nome_facebook: params[:nome_facebook_conjuge].gsub(/\s+/, " ").strip,
                                              email_facebook: params[:email_facebook_conjuge],
                                              url_facebook: params[:url_facebook_conjuge].strip.split("?")[0],
                                              url_imagem_facebook: params[:imagem_facebook_conjuge].strip,
                                              telefones: telefones,
                                              instrumentos: instrumentos)
      hash.permit!
      return hash
    end

    def pegar_telefones(numeros, operadoras)
      telefones = []

      if numeros.present? && operadoras.present?
        numeros.each_with_index do |numero_telefone, index|
          operadora = operadoras[index]

          if numero_telefone.present? && operadora.present?
            telefones << Telefone.new(telefone: numero_telefone, operadora: operadora)
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
      ['pessoa', 'conjuge'].each do |tipo_pessoa|
        pessoa = instance_variable_get("@#{tipo_pessoa}")

        grupos = instance_variable_get("@grupos_auto_inserir_#{tipo_pessoa}")
        coordenadores = instance_variable_get("@coordenadores_auto_inserir_#{tipo_pessoa}")
        encontros = instance_variable_get("@encontros_auto_inserir_#{tipo_pessoa}")
        sugestoes = instance_variable_get("@sugestoes_auto_inserir_#{tipo_pessoa}")

        if grupos.present?
          grupos.each_with_index do |grupo_id, indice|
            eh_coordenador = coordenadores[indice] == "true"
            texto_sugestao = sugestoes[indice]
            encontro_id = encontros[indice]

            if texto_sugestao != ''
              auto_sugestao = nil
              if texto_sugestao == 'so_grupo'
                auto_sugestao = AutoSugestao.where({pessoa: pessoa, grupo_id: grupo_id}).first
              end

              if auto_sugestao.nil?
                auto_sugestao = AutoSugestao.new({pessoa: pessoa, grupo_id: grupo_id})
              end

              if encontro_id != "-1"
                auto_sugestao.encontro_id = encontro_id
              end

              auto_sugestao.sugestao = texto_sugestao
              auto_sugestao.coordenador = eh_coordenador

              auto_sugestao.save
            end
          end
        end
      end
    end

    def pode_excluir_pessoa pessoa
      if @usuario_logado.eh_super_admin? || (@usuario_logado.eh_coordenador_de_grupo_de(pessoa) && !pessoa.eh_super_admin?)
        return true
      end

      return false
    end

    def pode_editar_pessoa pessoa
      if @usuario_logado == pessoa ||
          @usuario_logado.eh_super_admin? ||
          @usuario_logado.eh_coordenador_de_grupo_de(pessoa) ||
          @usuario_logado.conjuge == pessoa
        return true
      end

      return false
    end

    def pode_ver_pessoa pessoa
      if @usuario_logado.eh_super_admin? ||
          @usuario_logado.eh_coordenador_de_grupo_de(pessoa) ||
          @usuario_logado.eh_coordenador_de_encontro_de(pessoa) ||
          @usuario_logado.grupos_que_coordena.count > 0 ||
          @usuario_logado == pessoa
        return true
      end

      return false
    end

    def precisa_poder_editar_pessoa pessoa
      if !pode_editar_pessoa pessoa
        redirect_to root_url and return
      end
    end

    def precisa_poder_ver_pessoa pessoa
      if !pode_ver_pessoa pessoa
        redirect_to root_url and return
      end
    end

    def pode_ver_participacao conjunto, pessoa
      return @usuario_logado.eh_super_admin? ||
          @usuario_logado.eh_coordenador_de_algum_grupo_que_tem_encontros ||
          @usuario_logado.eh_coordenador_de_encontro_de(pessoa) ||
          @usuario_logado.eh_coordenador_de_conjunto_permanente_de(pessoa) ||
          @usuario_logado == pessoa
    end

    def pode_pesquisar_pessoas
      if @usuario_logado.eh_super_admin? || (@usuario_logado.grupos_que_tem_encontros_que_coordena.count > 0)
        return true
      end

      return false
    end

    def precisa_poder_pesquisar_pessoas
      if !pode_pesquisar_pessoas
        redirect_to root_url and return
      end
    end

    def pode_criar_pessoas_em_grupo grupo_id
      if @usuario_logado.eh_super_admin? || 
        @usuario_logado.grupos_que_coordena.collect{|g| g.slug}.include?(grupo_id) || 
        @usuario_logado.grupos_que_coordena.collect{|g| g.id.to_s}.include?(grupo_id)
        return true
      end

      return false
    end

    def precisa_poder_criar_pessoas
      if params[:grupo_id]
        if !pode_criar_pessoas_em_grupo params[:grupo_id]
          redirect_to root_url and return
        end
      else
        if !@usuario_logado.eh_super_admin?
          redirect_to root_url and return
        end
      end
    end

    def salvar_relacao_grupo pessoa, grupo
      relacao_pessoa = RelacaoPessoaGrupo.where({:pessoa_id => pessoa.id, :grupo_id => grupo.id})
      
      if relacao_pessoa.nil?
        relacao_pessoa = RelacaoPessoaGrupo.new({:pessoa_id => pessoa.id, :grupo_id => grupo.id})
        relacao_pessoa.save
      end

      if pessoa.conjuge.present?
        relacao_conjuge = RelacaoPessoaGrupo.where({:pessoa_id => pessoa.conjuge.id, :grupo_id => grupo.id}).first

        if relacao_conjuge.nil?
          relacao_conjuge = RelacaoPessoaGrupo.new({:pessoa_id => pessoa.conjuge.id, :grupo_id => grupo.id})
          relacao_conjuge.save
        end
      end
    end

    def salvar_relacao_conjunto pessoa, conjunto
      relacao_pessoa = RelacaoPessoaConjunto.where({:pessoa_id => pessoa.id, :conjunto_pessoas_id => conjunto.id})

      if relacao_pessoa.nil?
        relacao_pessoa = RelacaoPessoaConjunto.new({:pessoa_id => pessoa.id, :conjunto_pessoas_id => conjunto.id})
        relacao_pessoa.save
      end

      if pessoa.conjuge.present?
        relacao_conjuge = RelacaoPessoaConjunto.where({:pessoa_id => pessoa.conjuge.id, :conjunto_pessoas_id => conjunto.id}).first

        if relacao_conjuge.nil?
          relacao_conjuge = RelacaoPessoaConjunto.new({:pessoa_id => pessoa.conjuge.id, :conjunto_pessoas_id => conjunto.id})
          relacao_conjuge.save
        end
      end

      salvar_relacao_grupo(pessoa, conjunto.grupo)
    end



end
