class GruposController < ApplicationController
  before_action :set_grupo, only: [:show, :edit, :update, :destroy]
  before_action :adicionar_breadcrumbs_controller

  def adicionar_breadcrumbs_controller
    adicionar_breadcrumb "Grupos", grupos_url, "grupos"
  end

  # GET /grupos
  # GET /grupos.json
  def index
    precisa_poder_ver_grupos

    if @usuario_logado.eh_super_admin?
      @grupos = Grupo.all.page params[:page]
      @total = Grupo.all.count
    else
      @grupos = Kaminari.paginate_array(@usuario_logado.grupos_que_coordena).page params[:page]
      @total = @usuario_logado.grupos_que_coordena.count
    end

  end

  # GET /grupos/new
  def new
    precisa_ser_super_admin

    adicionar_breadcrumb "Criar novo grupo", new_grupo_path, "criar"

    @grupo = Grupo.new
  end

  # GET /grupos/1/edit
  def edit
    precisa_poder_gerenciar @grupo

    adicionar_breadcrumb "Editar #{@grupo.nome}", edit_grupo_path(@grupo), "editar"

    session[:pessoas] = @grupo.pessoas
    @tipo_pagina = "pessoas_no_grupo"

    @pessoa = Pessoa.new if @pessoa.nil?

    if @conjuge.nil?
      if @pessoa.conjuge.present?
        @conjuge = @pessoa.conjuge
      else
        @conjuge = Pessoa.new
      end
    end

  end

  # POST /grupos
  # POST /grupos.json
  def create
    precisa_ser_super_admin

    adicionar_breadcrumb "Criar novo grupo", new_grupo_path, "criar"

    @grupo = Grupo.new(grupo_params)
    @grupo.usuario_corrente = @usuario_logado

    respond_to do |format|
      if @grupo.save
        format.html { redirect_to grupos_url, notice: 'Grupo criado com sucesso.' }
        format.json { render action: 'show', status: :created, location: @grupo }
      else
        format.html { render action: 'new' }
        format.json { render json: @grupo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /grupos/1
  # PATCH/PUT /grupos/1.json
  def update
    precisa_ser_super_admin

    adicionar_breadcrumb "Editar #{@grupo.nome}", edit_grupo_path(@grupo), "editar"

    @pessoa = Pessoa.new if @pessoa.nil?
    @grupo.usuario_corrente = @usuario_logado

    respond_to do |format|
      if @grupo.update(grupo_params)
        format.html { redirect_to grupos_url, notice: 'Grupo editado com sucesso.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @grupo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /grupos/1
  # DELETE /grupos/1.json
  def destroy
    precisa_ser_super_admin

    @grupo.usuario_corrente = @usuario_logado
    @grupo.destroy

    numero_pagina = params[:page].to_i
    if Grupo.all.count < (APP_CONFIG['items_per_page'] * (numero_pagina - 1) + 1)
      numero_pagina -= 1
    end

    respond_to do |format|
      format.html { redirect_to grupos_path(page: numero_pagina) }
      format.json { head :no_content }
    end
  end

  def setar_eh_coordenador
    precisa_ser_super_admin

    precisa_salvar_relacao_pessoa = true
    precisa_salvar_relacao_conjuge = false

    pessoa = Pessoa.find(params[:pessoa_id])

    relacao_pessoa = RelacaoPessoaGrupo.where({:pessoa_id => pessoa.id, :grupo_id => params[:grupo_id]}).first
    relacao_pessoa.eh_coordenador = params[:eh_coordenador]

    if pessoa.conjuge.present?
      relacao_conjuge = RelacaoPessoaGrupo.where({:pessoa_id => pessoa.conjuge.id, :grupo_id => params[:grupo_id]}).first
      relacao_conjuge.eh_coordenador = params[:eh_coordenador]

      precisa_salvar_relacao_conjuge = true
    end

    if precisa_salvar_relacao_pessoa
      relacao_pessoa.usuario_corrente = @usuario_logado
    end

    if precisa_salvar_relacao_conjuge
      relacao_conjuge.usuario_corrente = @usuario_logado
    end

    if ((precisa_salvar_relacao_pessoa && relacao_pessoa.save) || !precisa_salvar_relacao_pessoa) &&
        ((precisa_salvar_relacao_conjuge && relacao_conjuge.save) || !precisa_salvar_relacao_conjuge)
      render :text => "ok"
    else
      render :text => "erro"
    end
  end

  def adicionar_pessoa_a_grupo
    precisa_salvar_relacao_pessoa = false

    @grupo = Grupo.find(params[:id_grupo])
    @pessoa = Pessoa.find(params[:id_pessoa])

    precisa_poder_gerenciar @grupo

    relacao_pessoa = RelacaoPessoaGrupo.where({:pessoa => @pessoa, :grupo_id => params[:id_grupo]}).first

    if relacao_pessoa.nil?
      precisa_salvar_relacao_pessoa = true
      relacao_pessoa = RelacaoPessoaGrupo.new({:pessoa => @pessoa, :grupo_id => params[:id_grupo]})
    end

    if @pessoa.conjuge.present?
      relacao_conjuge = RelacaoPessoaGrupo.where({:pessoa => @pessoa.conjuge, :grupo_id => params[:id_grupo]}).first
      if relacao_conjuge.nil?
        precisa_salvar_relacao_conjuge = true
        relacao_conjuge = RelacaoPessoaGrupo.new({:pessoa => @pessoa.conjuge, :grupo_id => params[:id_grupo]})
      end

      msg_sucesso = "Casal adicionado ao grupo com sucesso"
    else
      msg_sucesso = "Pessoa adicionada ao grupo com sucesso"
    end

    if precisa_salvar_relacao_pessoa
      relacao_pessoa.usuario_corrente = @usuario_logado
    end

    if precisa_salvar_relacao_conjuge
      relacao_conjuge.usuario_corrente = @usuario_logado
    end

    respond_to do |format|
      if ((precisa_salvar_relacao_pessoa && relacao_pessoa.save) || !precisa_salvar_relacao_pessoa) &&
          ((precisa_salvar_relacao_conjuge && relacao_conjuge.save) || !precisa_salvar_relacao_conjuge)
        format.json { render json: {msgSucesso: msg_sucesso}, status: :ok }
      else
        format.json { render json: @pessoa.errors, status: :unprocessable_entity }
      end
    end
  end

  def remover_pessoa_de_grupo
    @grupo = Grupo.find(params[:id_grupo])

    precisa_poder_gerenciar @grupo

    condicoes = ["grupo_id = #{@grupo.id}"]

    @pessoa = Pessoa.find(params[:id_pessoa])
    eh_casal = @pessoa.conjuge.present?

    condicoes_pessoas = ["pessoa_id = #{@pessoa.id}"]
    if eh_casal
      condicoes_pessoas << ["pessoa_id = #{@pessoa.conjuge.id}"]
    end
    condicoes_pessoas = condicoes_pessoas.join(" OR ")

    condicoes << condicoes_pessoas
    condicoes = condicoes.join(" AND ")

    RelacaoPessoaGrupo.where(condicoes).each { |relacao|
      relacao.usuario_corrente = @usuario_logado

      if params[:tipo_remover] == 'acidente'
        relacao.destroy
      elsif params[:tipo_remover] == 'saindo'
        relacao.deixou_de_participar_em = Date.strptime(params[:deixou_de_participar_em], '%d/%m/%Y')
        relacao.save
      end
    }

    if eh_casal
      msg_sucesso = "Casal removido do grupo com sucesso"
    else
      msg_sucesso = "Pessoa removida do grupo com sucesso"
    end

    numero_pagina = params[:page].to_i
    if @grupo.pessoas.count < (APP_CONFIG['items_per_page'] * (numero_pagina - 1) + 1)
      numero_pagina -= 1
    end

    respond_to do |format|
      format.json { render json: {novaPagina: numero_pagina, msgSucesso: msg_sucesso}, status: :ok }
    end

  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_grupo
      @grupo = Grupo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def grupo_params
      params.require(:grupo).permit(:nome, :eh_super_grupo)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pessoa_params
      hash = ActionController::Parameters.new(nome: params[:nome_pessoa],
                                              nome_usual: params[:nome_usual_pessoa],
                                              id_facebook: params[:id_facebook_pessoa],
                                              dia: params[:dia_pessoa],
                                              mes: params[:mes_pessoa],
                                              ano: params[:ano_pessoa],
                                              eh_homem: params[:eh_homem_pessoa])
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
                                              eh_homem: params[:eh_homem_conjuge])
      hash.permit!
      return hash
    end

    def pode_ver_grupos
      return @usuario_logado.eh_super_admin? || @usuario_logado.grupos_que_coordena.count > 0
    end

    def precisa_poder_ver_grupos
      if !pode_ver_grupos
        redirect_to root_url and return
      end
    end

    def pode_gerenciar grupo
      return @usuario_logado.eh_super_admin? || grupo.coordenadores.include?(@usuario_logado)
    end

    def precisa_poder_gerenciar grupo
      if !pode_gerenciar(grupo)
        redirect_to root_url and return
      end
    end
end
