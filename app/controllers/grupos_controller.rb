#encoding: utf-8

class GruposController < ApplicationController
  before_action :set_grupo, only: [:show, :edit, :update, :destroy]
  before_action :adicionar_breadcrumbs_controller
  skip_before_filter :precisa_estar_logado, :only => [:encontros_de_grupo]
  skip_before_action :adicionar_breadcrumbs_controller, only: [:encontros_de_grupo]

  def adicionar_breadcrumbs_controller
    if @usuario_logado.eh_super_admin
      adicionar_breadcrumb "Grupos", grupos_url, "grupos"
    end
  end

  # GET /grupos
  # GET /grupos.json
  def index
    precisa_ser_super_admin
    return if performed?

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
    return if performed?

    adicionar_breadcrumb "Criar novo grupo", new_grupo_path, "criar"

    @grupo = Grupo.new
  end

  # GET /grupos/1
  def show
    precisa_poder_gerenciar_grupo @grupo
    return if performed?

    adicionar_breadcrumb @grupo.nome, @grupo, "editar"

    carregar_pessoas(@grupo.pessoas)
    @tipo_pagina = "pessoas_no_grupo"
  end

  # POST /grupos
  # POST /grupos.json
  def create
    precisa_ser_super_admin
    return if performed?

    adicionar_breadcrumb "Criar novo grupo", new_grupo_path, "criar"

    @grupo = Grupo.new(grupo_params)

    respond_to do |format|
      if @grupo.valid?
        if @grupo.tem_encontros
          encontro_padrao = Encontro.new({
            padrao: 1, 
            nome: 'Padrão', 
            denominacao_conjuntos_permanentes: 'Círculo'})
          @grupo.encontro_padrao = encontro_padrao
        end

        @grupo.save

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
    return if performed?

    adicionar_breadcrumb @grupo.nome, @grupo, "editar"

    @pessoa = Pessoa.new if @pessoa.nil?

    respond_to do |format|
      if @grupo.update(grupo_params)
        if @grupo.tem_encontros
          encontro_padrao = Encontro.new({
            padrao: 1, 
            nome: 'Padrão', 
            denominacao_conjuntos_permanentes: 'Círculo'})
          @grupo.encontro_padrao = encontro_padrao
          @grupo.save
        end

        format.html { redirect_to grupos_url, notice: 'Grupo editado com sucesso.' }
        format.json { head :no_content }
      else
        format.html { render action: 'show' }
        format.json { render json: @grupo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /grupos/1
  # DELETE /grupos/1.json
  def destroy
    precisa_ser_super_admin
    return if performed?

    @grupo.destroy

    numero_pagina = params[:page].to_i
    if Grupo.all.count < (APP_CONFIG['items_per_page'] * (numero_pagina - 1) + 1)
      numero_pagina -= 1
    end

    session[:notificacao] = "Grupo excluído com sucesso"

    respond_to do |format|
      format.html { redirect_to grupos_path(page: numero_pagina) }
      format.json { head :no_content }
    end
  end

  def setar_eh_coordenador
    precisa_ser_super_admin
    return if performed?

    precisa_salvar_relacao_pessoa = true
    precisa_salvar_relacao_conjuge = false

    pessoa = Pessoa.find(params[:pessoa_id])
    grupo = Grupo.find(params[:grupo_id])

    relacao_pessoa = RelacaoPessoaGrupo.where({:pessoa_id => pessoa.id, :grupo_id => params[:grupo_id]}).first
    relacao_pessoa.eh_coordenador = params[:eh_coordenador]

    if pessoa.conjuge.present?
      relacao_conjuge = RelacaoPessoaGrupo.where({:pessoa_id => pessoa.conjuge.id, :grupo_id => params[:grupo_id]}).first

      if relacao_conjuge.present?
        relacao_conjuge.eh_coordenador = params[:eh_coordenador]
        precisa_salvar_relacao_conjuge = true
      end
    end

    if ((precisa_salvar_relacao_pessoa && relacao_pessoa.save) || !precisa_salvar_relacao_pessoa) &&
        ((precisa_salvar_relacao_conjuge && relacao_conjuge.save) || !precisa_salvar_relacao_conjuge)
      carregar_pessoas(grupo.pessoas)
      if params[:eh_coordenador] == "true"
        render :text => 1
      else
        render :text => params[:page]
      end

    else
      render :text => "erro"
    end
  end

  def adicionar_pessoa_a_grupo
    precisa_salvar_relacao_pessoa = false

    @grupo = Grupo.find(params[:id_grupo])

    if params[:so_um_ou_os_dois].nil? || params[:so_um_ou_os_dois] == 'os_dois'
      @pessoa = Pessoa.find(params[:id_pessoa])
      @conjuge = @pessoa.conjuge
    elsif params[:so_um_ou_os_dois] == 'so_pessoa'
      @pessoa = Pessoa.find(params[:id_pessoa])
      @conjuge = nil
    elsif params[:so_um_ou_os_dois] == 'so_conjuge'
      @pessoa = Pessoa.find(params[:id_pessoa]).conjuge
      @conjuge = nil
    end

    precisa_poder_gerenciar_grupo @grupo
    return if performed?

    relacao_pessoa = RelacaoPessoaGrupo.where({:pessoa => @pessoa, :grupo_id => params[:id_grupo]}).first

    if relacao_pessoa.nil?
      precisa_salvar_relacao_pessoa = true
      relacao_pessoa = RelacaoPessoaGrupo.new({:pessoa => @pessoa, :grupo_id => params[:id_grupo]})
    end

    if @conjuge.present?
      relacao_conjuge = RelacaoPessoaGrupo.where({:pessoa => @conjuge, :grupo_id => params[:id_grupo]}).first
      if relacao_conjuge.nil?
        precisa_salvar_relacao_conjuge = true
        relacao_conjuge = RelacaoPessoaGrupo.new({:pessoa => @conjuge, :grupo_id => params[:id_grupo]})
      end

      msg_sucesso = "Casal adicionado ao grupo com sucesso"
    else
      msg_sucesso = "Pessoa adicionada ao grupo com sucesso"
    end

    respond_to do |format|
      if ((precisa_salvar_relacao_pessoa && relacao_pessoa.save) || !precisa_salvar_relacao_pessoa) &&
          ((precisa_salvar_relacao_conjuge && relacao_conjuge.save) || !precisa_salvar_relacao_conjuge)
        carregar_pessoas(@grupo.pessoas)
        format.json { render json: {msgSucesso: msg_sucesso}, status: :ok }
        format.html { redirect_to pessoa_url(@pessoa), notice: msg_sucesso }
      else
        format.json { render json: @pessoa.errors, status: :unprocessable_entity }
        format.html { redirect_to pessoa_url(@pessoa) }
      end
    end
  end

  def remover_pessoa_de_grupo
    @grupo = Grupo.find(params[:id_grupo])

    precisa_poder_gerenciar_grupo @grupo
    return if performed?

    condicoes = ["grupo_id = #{@grupo.id}"]

    @pessoa = Pessoa.find(params[:id_pessoa])
    eh_casal = @pessoa.conjuge.present?

    condicoes_pessoas = ["pessoa_id = #{@pessoa.id}"]
    if eh_casal
      condicoes_pessoas << ["pessoa_id = #{@pessoa.conjuge.id}"]
    end
    condicoes_pessoas = "(#{condicoes_pessoas.join(" OR ")})"

    condicoes << condicoes_pessoas
    condicoes = condicoes.join(" AND ")

    if params[:ex_participante]
      relacoes = RelacaoPessoaGrupo.unscoped.where(condicoes)
    else
      relacoes = RelacaoPessoaGrupo.where(condicoes)
    end

    relacoes.each do |relacao|
      if params[:tipo_remover] == 'acidente' || params[:tipo_remover] == 'remover_ex'
        relacao.destroy

        conjuntos = []
        @grupo.encontros.each do |encontro|
          conjuntos += encontro.conjuntos.collect{|conjunto| conjunto.id}
        end

        condicoes_conjunto_array = []
        if conjuntos.count > 0
          condicoes_conjunto_array = ["conjunto_pessoas_id IN (#{conjuntos.join(", ")})"]
        end

        condicoes_conjunto_array << condicoes_pessoas

        condicoes_conjunto = condicoes_conjunto_array.join(" AND ")

        RelacaoPessoaConjunto.where(condicoes_conjunto).each do |relacao_conjunto|
          relacao_conjunto.destroy
        end

      elsif params[:tipo_remover] == 'saindo'
        relacao.deixou_de_participar_em = Date.strptime(params[:deixou_de_participar_em], '%d/%m/%Y')
        relacao.save
      end
    end

    if eh_casal
      msg_sucesso = "Casal removido do grupo com sucesso"
    else
      msg_sucesso = "Pessoa removida do grupo com sucesso"
    end

    if params[:tipo_remover] == 'remover_ex'
      carregar_pessoas(@grupo.ex_relacoes.collect{|r| r.pessoa}.uniq)
    else
      carregar_pessoas(@grupo.pessoas)
    end

    numero_pagina = params[:page].to_i
    if @grupo.pessoas.count < (APP_CONFIG['items_per_page'] * (numero_pagina - 1) + 1)
      numero_pagina -= 1
    end

    respond_to do |format|
      format.json { render json: {novaPagina: numero_pagina, msgSucesso: msg_sucesso}, status: :ok }
    end

  end

  def encontros_de_grupo
    @grupo = Grupo.find(params[:id])
    if @grupo
      render json: @grupo.encontros
    else
      render json: []
    end
  end

  def ex_participantes
    @grupo = Grupo.friendly.find(params[:grupo_id])

    precisa_poder_gerenciar_grupo @grupo
    return if performed?

    adicionar_breadcrumb @grupo.nome, @grupo, "editar"
    adicionar_breadcrumb "Ex-participantes", grupo_ex_participantes_url(@grupo), "ex_participantes"

    carregar_pessoas(@grupo.ex_relacoes.collect{|r| r.pessoa}.uniq)

    @tipo_pagina = "ex_participantes_de_grupo"
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_grupo
      @grupo = Grupo.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def grupo_params
      params[:grupo][:outros_grupos_que_pode_ver_equipes] = []

      if params[:outros_grupos_que_pode_ver_equipes].present? && params[:grupo][:tem_encontros].present? && params[:grupo][:tem_encontros] == "1"
        params[:outros_grupos_que_pode_ver_equipes].each do |outro_grupo_id|
          params[:grupo][:outros_grupos_que_pode_ver_equipes] << Grupo.find(outro_grupo_id)
        end
      end

      params_grupo = params[:grupo]

      hash = ActionController::Parameters.new(nome: params_grupo[:nome],
                                              tem_encontros: params_grupo[:tem_encontros],
                                              outros_grupos_que_pode_ver_equipes: params_grupo[:outros_grupos_que_pode_ver_equipes],
                                              slug: nil)
      hash.permit!
      return hash
    end

    def precisa_poder_gerenciar_grupo grupo
      if !@usuario_logado.permissoes.pode_gerenciar_grupo(grupo)
        redirect_to root_url and return
      end
    end

end
