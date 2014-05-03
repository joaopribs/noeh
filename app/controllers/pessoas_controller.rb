#encoding: utf-8

class PessoasController < ApplicationController
  before_action :set_pessoa, only: [:show, :edit, :update, :destroy]
  before_action :adicionar_breadcrumbs_controller

  def adicionar_breadcrumbs_controller
    adicionar_breadcrumb "Pessoas", pessoas_url, "pessoas"
  end

  # GET /pessoas
  # GET /pessoas.json
  def index
    precisa_ser_super_admin
    session[:pessoas] = Pessoa.all
    @tipo_pagina = "lista_pessoas"
  end

  # GET /pessoas/1
  # GET /pessoas/1.json
  def show
    precisa_poder_ver_pessoa @pessoa

    @nome_usual = @pessoa.nome_usual
    if @pessoa.conjuge.present?
      @nome_usual += " / #{@pessoa.conjuge.nome_usual}"
    end

    if params.has_key?(:grupo_id)
      iniciar_breadcrumbs
      adicionar_breadcrumb "Grupos", grupos_url, "grupos"

      @grupo = Grupo.find(params[:grupo_id])
      adicionar_breadcrumb "Editar #{@grupo.nome}", edit_grupo_path(@grupo), "editar"

      adicionar_breadcrumb @nome_usual, pessoa_url(@pessoa), "ver"
    else
      adicionar_breadcrumb @nome_usual, pessoa_url(@pessoa), "ver"
    end

    @conjuge = @pessoa.conjuge

  end

  # GET /pessoas/new
  def new
    precisa_poder_criar_pessoas

    if params.has_key?(:grupo_id)
      iniciar_breadcrumbs
      adicionar_breadcrumb "Grupos", grupos_url, "grupos"
      @grupo = Grupo.find(params[:grupo_id])
      adicionar_breadcrumb "Editar #{@grupo.nome}", edit_grupo_path(@grupo), "editar_grupo"
    end

    adicionar_breadcrumb "Criar nova pessoa", new_pessoa_url, "criar"

    @pessoa = Pessoa.new
    @conjuge = Pessoa.new
  end

  # GET /pessoas/1/edit
  def edit
    precisa_poder_editar_pessoa @pessoa

    @eh_casal = @pessoa.conjuge.present?

    if @eh_casal
      precisa_poder_editar_pessoa @pessoa.conjuge
      @conjuge = @pessoa.conjuge
      @tipo_conjuge = 'form'
    else
      @conjuge = Pessoa.new
    end

    if params.has_key?(:grupo_id)
      iniciar_breadcrumbs
      adicionar_breadcrumb "Grupos", grupos_url, "grupos"

      @grupo = Grupo.find(params[:grupo_id])
      adicionar_breadcrumb "Editar #{@grupo.nome}", edit_grupo_path(@grupo), "editar_grupo"
    end

    @nome_usual = @pessoa.nome_usual
    if @pessoa.conjuge.present?
      @nome_usual += " / #{@pessoa.conjuge.nome_usual}"
    end

    adicionar_breadcrumb "Editar #{@nome_usual}", edit_pessoa_url(@pessoa), "editar"

  end

  # POST /pessoas
  # POST /pessoas.json
  def create
    precisa_poder_criar_pessoas

    if params.has_key?(:grupo_id)
      iniciar_breadcrumbs
      adicionar_breadcrumb "Grupos", grupos_url, "grupos"
      @grupo = Grupo.find(params[:grupo_id])
      adicionar_breadcrumb "Editar #{@grupo.nome}", edit_grupo_path(@grupo), "editar_grupo"
    end

    adicionar_breadcrumb "Criar nova pessoa", new_pessoa_url, "criar"

    @pessoa = Pessoa.new(pessoa_params)
    @pessoa.usuario_corrente = @usuario_logado

    @eh_casal = params[:casado_ou_solteiro] == 'casado'

    if @eh_casal
      msg_sucesso = "Casal criado com sucesso"

      @tipo_conjuge = params[:tipo_de_conjuge_escolhido]

      if @tipo_conjuge == "ja_cadastrado" && !params[:id_conjuge].blank?
        @conjuge = Pessoa.find(params[:id_conjuge])
        @tipo_conjuge = 'ja_cadastrado'
      else
        @conjuge = Pessoa.new(conjuge_params)
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

      @conjuge.valid?

      casal_valido = @pessoa.valid? && @conjuge.valid?

      if casal_valido
        @pessoa.conjuge = @conjuge
        @conjuge.conjuge = @pessoa

        @conjuge.usuario_corrente = @usuario_logado
      end
    else
      msg_sucesso = "Pessoa criada com sucesso"
      @conjuge = Pessoa.new
    end

    pagina_retorno_sucesso = pessoas_path

    respond_to do |format|
      if (@eh_casal && casal_valido && @pessoa.save && @conjuge.save) ||
        (!@eh_casal && @pessoa.save)

        if params.has_key?(:grupo_id)
          relacao_pessoa = RelacaoPessoaGrupo.new({:pessoa_id => @pessoa.id, :grupo_id => params[:grupo_id]})
          relacao_pessoa.usuario_corrente = @usuario_logado
          relacao_pessoa.save

          if @eh_casal
            relacao_conjuge = RelacaoPessoaGrupo.where({:pessoa_id => @conjuge.id, :grupo_id => params[:grupo_id]}).first

            if relacao_conjuge.nil?
              relacao_conjuge = RelacaoPessoaGrupo.new({:pessoa_id => @conjuge.id, :grupo_id => params[:grupo_id]})
            end

            relacao_conjuge.usuario_corrente = @usuario_logado
            relacao_conjuge.save

            msg_sucesso = "Casal criado e adicionado a #{@grupo.nome} com sucesso"
          else
            msg_sucesso = "Pessoa criada e adicionada a #{@grupo.nome} com sucesso"
          end

          pagina_retorno_sucesso = edit_grupo_path(@grupo)
        end

        format.html { redirect_to pagina_retorno_sucesso, notice: msg_sucesso }
        format.json { render action: 'show', status: :created, location: @pessoa }
      else
        format.html { render action: 'new' }
        format.json { render json: @pessoa.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pessoas/1
  # PATCH/PUT /pessoas/1.json
  def update
    precisa_poder_editar_pessoa @pessoa

    if params.has_key?(:grupo_id)
      iniciar_breadcrumbs
      adicionar_breadcrumb "Grupos", grupos_url, "grupos"

      @grupo = Grupo.find(params[:grupo_id])
      adicionar_breadcrumb "Editar #{@grupo.nome}", edit_grupo_path(@grupo), "editar_grupo"
    end

    @nome_usual = @pessoa.nome_usual
    if @pessoa.conjuge.present?
      @nome_usual += " / #{@pessoa.conjuge.nome_usual}"
    end

    adicionar_breadcrumb "Editar #{@nome_usual}", edit_pessoa_url(@pessoa), "editar"

    @pessoa.assign_attributes(pessoa_params)

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
          @conjuge.assign_attributes(conjuge_params)
        else
          @conjuge = Pessoa.new(conjuge_params)
        end

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

    pagina_retorno_sucesso = pessoas_path

    if params.has_key?(:grupo_id)
      pagina_retorno_sucesso = edit_grupo_path(@grupo)
    end

    if precisa_salvar_pessoa
      @pessoa.usuario_corrente = @usuario_logado
    end
    if precisa_salvar_conjuge
      @conjuge.usuario_corrente = @usuario_logado
    end
    if precisa_salvar_velho_conjuge
      @velho_conjuge.usuario_corrente = @usuario_logado
    end

    respond_to do |format|
      if ((precisa_salvar_pessoa && @pessoa.save) || !precisa_salvar_pessoa) &&
          ((precisa_salvar_conjuge && @conjuge.save) || !precisa_salvar_conjuge) &&
          ((precisa_salvar_velho_conjuge && @velho_conjuge.save) || !precisa_salvar_velho_conjuge)
        format.html { redirect_to pagina_retorno_sucesso, notice: msg_sucesso }
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
      @pessoa.usuario_corrente = @usuario_logado
      @pessoa.destroy
    end

    numero_pagina = params[:page].to_i
    if Pessoa.all.count < (APP_CONFIG['items_per_page'] * (numero_pagina - 1) + 1)
      numero_pagina -= 1
    end

    msg_sucesso = @pessoa.conjuge.present? ? 'Casal excluído com sucesso' : 'Pessoa excluída com sucesso'

    flash[:notice] = msg_sucesso

    respond_to do |format|
      # format.html { redirect_to pessoas_url, notice: msg_sucesso, status: 303 } # Status 303 eh pq ta vindo de um method DELETE e redirecionando pra um GET
      format.json { render json: {novaPagina: numero_pagina, msgSucesso: msg_sucesso}, status: :ok }
    end
  end

  def consulta_ja_existe_fb
    ja_existe = !Pessoa.where(:id_facebook => params[:id_facebook]).empty?

    respond_to do |format|
      if ja_existe
        format.json { render json: {}, status: :unprocessable_entity }
      else
        format.json { render json: {}, status: :ok }
      end
    end
  end

  def pesquisa_pessoas
    condicoes = []

    if params.has_key? :query
      condicoes << "(nome LIKE '%#{params[:query]}%' OR nome_usual LIKE '%#{params[:query]}%')"
    end

    if params.has_key? :id_grupo_ignorar
      grupo_ignorar = Grupo.find(params[:id_grupo_ignorar])
      id_pessoas_ignorar = grupo_ignorar.pessoas.collect{ |p| p.id }

      if id_pessoas_ignorar.count > 0
        condicoes << "id NOT IN (#{id_pessoas_ignorar.join(",")})"
      end
    end

    if params.has_key? :pessoa_ignorar
      condicoes << "id != #{params[:pessoa_ignorar]}"
    end

    if params.has_key? :ignorar_casais
      condicoes << "conjuge_id IS NULL"
    end

    sql = condicoes.join(" AND ")
    pessoas = Pessoa.where(sql).order("nome ASC")

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
      else
        conjuge = nil
      end

      objetos << pessoa.attributes.merge({conjuge: conjuge})
    }

    respond_to do |format|
      format.json { render json: {pessoas: objetos, descricao_quantidade: descricao_quantidade} }
    end
  end

  def lista_pessoas
    pessoas_total = session[:pessoas]

    @pessoas = pessoas_total.page params[:page]
    @total = pessoas_total.count
    @numero_casais = pessoas_total.where("conjuge_id IS NOT NULL").count / 2

    @tipo_pagina = params[:tipo_pagina]

    if params.has_key?(:grupo_id)
      @grupo = Grupo.find(params[:grupo_id])
    end

    render :layout => false
  end

  def lista_pessoas_js
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pessoa
      @pessoa = Pessoa.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pessoa_params
      if params[:cep1_pessoa].present? || params[:cep2_pessoa].present?
        cep = "#{params[:cep1_pessoa]}-#{params[:cep2_pessoa]}"
      end

      hash = ActionController::Parameters.new(nome: params[:nome_pessoa],
                                              nome_usual: params[:nome_usual_pessoa],
                                              id_facebook: params[:id_facebook_pessoa],
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
                                              cep: cep)
      hash.permit!
      return hash
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def conjuge_params
      hash = ActionController::Parameters.new(nome: params[:nome_conjuge],
                                              nome_usual: params[:nome_usual_conjuge],
                                              id_facebook: params[:id_facebook_conjuge],
                                              dia: params[:dia_conjuge],
                                              mes: params[:mes_conjuge],
                                              ano: params[:ano_conjuge],
                                              eh_homem: params[:eh_homem_conjuge],
                                              email: params[:email_conjuge])
      hash.permit!
      return hash
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

    def pode_criar_pessoas
      if @usuario_logado.eh_super_admin? || (@usuario_logado.grupos_que_coordena.count > 0)
        return true
      end

      return false
    end

    def pode_ver_pessoa pessoa
      if @usuario_logado.eh_super_admin? || @usuario_logado.eh_coordenador_de_grupo_de(pessoa) || @usuario_logado == pessoa
        return true
      end

      return false
    end

    def precisa_poder_editar_pessoa pessoa
      if !pode_editar_pessoa pessoa
        redirect_to root_url and return
      end
    end

    def precisa_poder_criar_pessoas
      if !pode_criar_pessoas
        redirect_to root_url and return
      end
    end

    def precisa_poder_ver_pessoa pessoa
      if !pode_ver_pessoa pessoa
        redirect_to root_url and return
      end
    end

end
