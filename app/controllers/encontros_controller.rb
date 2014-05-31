#encoding: utf-8

class EncontrosController < ApplicationController
  before_action :set_encontro_e_grupo, :adicionar_breadcrumbs_controller

  def adicionar_breadcrumbs_controller
    adicionar_breadcrumb "Grupos", grupos_url, "grupos"
    adicionar_breadcrumb @grupo.nome, @grupo, "editar_grupo"
    adicionar_breadcrumb "Encontros", grupo_encontros_url(@grupo), "encontros"
  end

  def index
    @encontros = @grupo.encontros.page params[:page]
    @total = @grupo.encontros.count
  end

  def show
    adicionar_breadcrumb @encontro.nome, @encontro, "ver"
  end

  def new
    adicionar_breadcrumb "Criar novo encontro", new_grupo_encontro_url, "criar"
    @encontro = Encontro.new(grupo: @grupo)

    encontro_padrao = @grupo.encontro_padrao

    @encontro.equipes = encontro_padrao.equipes
    @encontro.conjuntos_permanentes = encontro_padrao.conjuntos_permanentes
  end

  def create
    adicionar_breadcrumb "Criar novo encontro", new_grupo_encontro_url, "criar"

    @encontro = Encontro.new(encontro_params)
    @encontro.grupo = @grupo

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
    adicionar_breadcrumb @encontro.nome, @encontro, "ver"
    adicionar_breadcrumb "Editar", edit_encontro_url(@encontro), "editar"
  end

  def update
    adicionar_breadcrumb @encontro.nome, @encontro, "ver"
    adicionar_breadcrumb "Editar", edit_encontro_url(@encontro), "editar"

    respond_to do |format|
      if @encontro.update(encontro_params)
        format.html { redirect_to @encontro, notice: "Encontro alterado com sucesso" }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @encontro.errors, status: :unprocessable_entity }
      end
    end
  end

  def forma_padrao
    adicionar_breadcrumb "Forma Padrão", grupo_padrao_url(@grupo), "padrao"

    @encontro = @grupo.encontro_padrao
    @padrao = true

    render action: 'edit'
  end

  def update_forma_padrao
    adicionar_breadcrumb "Forma Padrão", grupo_padrao_url(@grupo), "padrao"

    @encontro = @grupo.encontro_padrao

    respond_to do |format|
      if @encontro.update(encontro_params)
        format.html { redirect_to grupo_encontros_url(@grupo), notice: "Forma padrão para encontros de #{@grupo.nome} alterada com sucesso" }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @grupo.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
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
    def encontro_params
      nomes_equipes = params[:nomes_equipes]
      cores_equipes = params[:cores_equipes]

      equipes = []
      if nomes_equipes.present? && cores_equipes.present?
        nomes_equipes.each_with_index do |nome_equipe, index|
          cor_equipe = cores_equipes[index]

          if nome_equipe.present? || cor_equipe.present?
            equipes << Equipe.new({nome: nome_equipe, cor_id: cor_equipe})
          end
        end
      end

      nomes_conjuntos_permanentes = params[:nomes_conjuntos_permanentes]
      cores_conjuntos_permanentes = params[:cores_conjuntos_permanentes]

      conjuntos_permanentes = []
      if nomes_conjuntos_permanentes.present? && cores_conjuntos_permanentes.present?
        nomes_conjuntos_permanentes.each_with_index do |nome_conjunto_permanente, index|
          cor_conjunto_permanente = cores_conjuntos_permanentes[index]

          if nome_conjunto_permanente.present? || cor_conjunto_permanente.present?
            conjuntos_permanentes << ConjuntoPermanente.new({nome: nome_conjunto_permanente, cor_id: cor_conjunto_permanente})
          end
        end
      end

      data_inicio = Date.strptime(params[:data_inicio], '%d/%m/%Y') unless params[:data_inicio].blank?
      data_termino =  Date.strptime(params[:data_termino], '%d/%m/%Y') unless params[:data_termino].blank?
      data_liberacao = Date.strptime(params[:data_liberacao], '%d/%m/%Y') unless params[:data_liberacao].blank?
      data_fechamento = Date.strptime(params[:data_fechamento], '%d/%m/%Y') unless params[:data_fechamento].blank?

      hash = ActionController::Parameters.new(denominacao_conjuntos_permanentes: params[:denominacao_conjuntos_permanentes],
                                              nome: params[:nome],
                                              tema: params[:tema],
                                              data_inicio: data_inicio,
                                              data_termino: data_termino,
                                              data_liberacao: data_liberacao,
                                              data_fechamento: data_fechamento,
                                              equipes: equipes,
                                              conjuntos_permanentes: conjuntos_permanentes)
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

end