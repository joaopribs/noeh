#encoding: utf-8

class EncontrosController < ApplicationController
  before_action :set_encontro_e_grupo, :adicionar_breadcrumbs_controller

  def adicionar_breadcrumbs_controller
    if @usuario_logado.eh_super_admin?
      adicionar_breadcrumb "Grupos", grupos_url, "grupos"
    end

    if eh_coordenador_do_grupo @grupo
      adicionar_breadcrumb @grupo.nome, @grupo, "editar_grupo"
      adicionar_breadcrumb "Encontros", grupo_encontros_url(@grupo), "encontros"
    end
  end

  def index
    precisa_ser_coordenador_do_grupo @grupo
    return if performed?

    @encontros = @grupo.encontros.page params[:page]
    @total = @grupo.encontros.count
  end

  def show
    precisa_ser_coordenador_do_grupo_ou_do_encontro @encontro
    return if performed?

    adicionar_breadcrumb @encontro.nome, @encontro, "ver"

    @equipe = Equipe.new(encontro: @encontro)
    @conjunto_permanente = ConjuntoPermanente.new(encontro: @encontro)
    @mostrar_form_equipe = false
    @mostrar_form_conjunto_permanente = false

    if session[:conjunto]
      conjunto = session[:conjunto]
      if conjunto.present? && conjunto.tipo == 'Equipe'
        @equipe = conjunto
        @mostrar_form_equipe
      elsif conjunto.present? && conjunto.tipo == 'ConjuntoPermanente'
        @conjunto_permanente = conjunto
        @mostrar_form_conjunto_permanente = true
      end
      session[:conjunto] = nil
    end
  end

  def new
    precisa_ser_coordenador_do_grupo @grupo
    return if performed?

    adicionar_breadcrumb "Criar novo encontro", new_grupo_encontro_url, "criar"
    @encontro = Encontro.new(grupo: @grupo)
    @encontro.denominacao_conjuntos_permanentes = @grupo.encontro_padrao.denominacao_conjuntos_permanentes
  end

  def create
    precisa_ser_coordenador_do_grupo @grupo
    return if performed?

    adicionar_breadcrumb "Criar novo encontro", new_grupo_encontro_url, "criar"

    @encontro = Encontro.new(encontro_params(false))
    @encontro.grupo = @grupo

    encontro_padrao = @grupo.encontro_padrao

    encontro_padrao.equipes.each do |equipe|
      equipe_encontro = equipe.dup
      equipe_encontro.equipe_padrao_relacionada = equipe
      @encontro.equipes << equipe_encontro
    end

    encontro_padrao.conjuntos_permanentes.each do |conjunto_permanente|
      @encontro.conjuntos_permanentes << conjunto_permanente.dup
    end

    respond_to do |format|
      if @encontro.save
        format.html { redirect_to @encontro, notice: 'Encontro criado com sucesso.' }
        format.json { render action: 'show', status: :created, location: @encontro }
      else
        format.html { render action: 'new' }
        format.json { render json: @encontro.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    precisa_ser_coordenador_do_grupo_ou_do_encontro @encontro
    return if performed?

    adicionar_breadcrumb @encontro.nome, @encontro, "ver"
    adicionar_breadcrumb "Editar", edit_encontro_url(@encontro), "editar"
  end

  def update
    precisa_ser_coordenador_do_grupo_ou_do_encontro @encontro
    return if performed?

    adicionar_breadcrumb @encontro.nome, @encontro, "ver"
    adicionar_breadcrumb "Editar", edit_encontro_url(@encontro), "editar"

    respond_to do |format|
      if @encontro.update(encontro_params(false))
        format.html { redirect_to @encontro, notice: "Encontro alterado com sucesso" }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @encontro.errors, status: :unprocessable_entity }
      end
    end
  end

  def forma_padrao
    precisa_ser_coordenador_do_grupo @grupo
    return if performed?

    adicionar_breadcrumb "Forma Padrão", grupo_padrao_url(@grupo), "padrao"

    @encontro = @grupo.encontro_padrao
    @padrao = true

    render action: 'edit'
  end

  def update_forma_padrao
    precisa_ser_coordenador_do_grupo @grupo
    return if performed?

    adicionar_breadcrumb "Forma Padrão", grupo_padrao_url(@grupo), "padrao"

    @encontro = @grupo.encontro_padrao

    respond_to do |format|
      if @encontro.update(encontro_params(true))
        format.html { redirect_to grupo_encontros_url(@grupo), notice: "Forma padrão para encontros de #{@grupo.nome} alterada com sucesso" }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @grupo.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    precisa_ser_coordenador_do_grupo @grupo
    return if performed?

    @encontro.destroy

    numero_pagina = params[:page].to_i
    if @grupo.encontros.count < (APP_CONFIG['items_per_page'] * (numero_pagina - 1) + 1)
      numero_pagina -= 1
    end

    session[:notificacao] = "Encontro excluído com sucesso"

    respond_to do |format|
      format.html { redirect_to grupo_encontros_url(@grupo, page: numero_pagina) }
      format.json { head :no_content }
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def encontro_params eh_padrao
      data_inicio = Date.strptime(params[:data_inicio], '%d/%m/%Y') unless params[:data_inicio].blank?
      data_termino =  Date.strptime(params[:data_termino], '%d/%m/%Y') unless params[:data_termino].blank?
      data_liberacao = Date.strptime(params[:data_liberacao], '%d/%m/%Y') unless params[:data_liberacao].blank?
      data_fechamento = Date.strptime(params[:data_fechamento], '%d/%m/%Y') unless params[:data_fechamento].blank?

      if eh_padrao
        nomes_equipes = params[:nomes_equipes]
        cores_equipes = params[:cores_equipes]
        ids_equipes = params[:ids_equipes]

        equipes = []
        if nomes_equipes.present? && cores_equipes.present? && ids_equipes.present?
          ids_equipes.each_with_index do |id_equipe, index|
            cor_equipe = cores_equipes[index]
            nome_equipe = nomes_equipes[index]

            if id_equipe != "-1"
              equipe = Equipe.find(id_equipe)
            end

            if nome_equipe.present?
              if equipe.nil?
                equipe = Equipe.new
              end

              equipe.nome = nome_equipe
              equipe.cor_id = cor_equipe

              # if id_equipe != "-1"
                equipe.save
              # end
            end

            if equipe.present?
              equipes << equipe
            end
          end
        end

        nomes_conjuntos_permanentes = params[:nomes_conjuntos_permanentes]
        cores_conjuntos_permanentes = params[:cores_conjuntos_permanentes]

        conjuntos_permanentes = []
        if nomes_conjuntos_permanentes.present? && cores_conjuntos_permanentes.present?
          nomes_conjuntos_permanentes.each_with_index do |nome_conjunto_permanente, index|
            cor_conjunto_permanente = cores_conjuntos_permanentes[index]

            if nome_conjunto_permanente.present?
              conjuntos_permanentes << ConjuntoPermanente.new({nome: nome_conjunto_permanente, cor_id: cor_conjunto_permanente})
            end
          end
        end

        params_padrao = {equipes: equipes,
                         conjuntos_permanentes: conjuntos_permanentes}
      end

      parametros = {}

      if params[:denominacao_conjuntos_permanentes]
        parametros[:denominacao_conjuntos_permanentes] = params[:denominacao_conjuntos_permanentes]
      end

      if params[:nome]
        parametros[:nome] = params[:nome]
      end

      if params[:tema]
        parametros[:tema] = params[:tema]
      end

      parametros.merge!({data_inicio: data_inicio,
                      data_termino: data_termino,
                      data_liberacao: data_liberacao,
                      data_fechamento: data_fechamento})

      if eh_padrao
        parametros.merge!(params_padrao)
      end

      hash = ActionController::Parameters.new(parametros)
      hash.permit!
      return hash
    end

    def set_encontro_e_grupo
      if params[:id]
        @encontro = Encontro.find(params[:id])
        @grupo = @encontro.grupo
      else
        if params[:grupo_id]
          @grupo = Grupo.friendly.find(params[:grupo_id])
        end
      end
    end

    def eh_coordenador_do_grupo grupo
      return @usuario_logado.eh_super_admin? || grupo.coordenadores.include?(@usuario_logado)
    end

    def precisa_ser_coordenador_do_grupo grupo
      if !eh_coordenador_do_grupo(grupo)
        redirect_to root_url and return
      end
    end

    def eh_coordenador_do_grupo_ou_do_encontro encontro
      return @usuario_logado.eh_super_admin? || encontro.coordenadores.include?(@usuario_logado) || encontro.grupo.coordenadores.include?(@usuario_logado)
    end

    def precisa_ser_coordenador_do_grupo_ou_do_encontro encontro
      if !eh_coordenador_do_grupo_ou_do_encontro(encontro)
        redirect_to root_url and return
      end
    end

end