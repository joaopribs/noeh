#encoding: utf-8

class ConjuntosPessoasController < ApplicationController
  before_action :set_encontro_grupo_e_conjunto, :adicionar_breadcrumbs_controller
  skip_before_action :adicionar_breadcrumbs_controller, only: [
      :adicionar_pessoa_a_conjunto, :remover_pessoa_de_conjunto, :setar_eh_coordenador
  ]

  def adicionar_breadcrumbs_controller
    adicionar_breadcrumb "Grupos", grupos_url, "grupos"
    adicionar_breadcrumb @grupo.nome, @grupo, "editar_grupo"
    adicionar_breadcrumb "Encontros", grupo_encontros_url(@grupo), "encontros"
    adicionar_breadcrumb @encontro.nome, @encontro, "encontro"
  end

  def create
    if params[:tipo_conjunto] == "Equipe"
      @conjunto = Equipe.new(conjunto_params)
    elsif params[:tipo_conjunto] == "ConjuntoPermanente"
      @conjunto = ConjuntoPermanente.new(conjunto_params)
    end

    @conjunto.encontro = @encontro

    @titulo = "Criar #{@conjunto.tipo_do_conjunto}"
    adicionar_breadcrumb @titulo, @conjunto, "conjunto"

    respond_to do |format|
      if @conjunto.update(conjunto_params)
        if @conjunto.tipo_do_conjunto == "Equipe"
          msg = "Equipe criada com sucesso"
        else
          msg = "#{@conjunto.tipo_do_conjunto.capitalize} criado com sucesso"
        end
        format.html { redirect_to @conjunto.encontro, notice: msg }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @conjunto.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @titulo = "#{@conjunto.tipo_do_conjunto} #{@conjunto.nome}"
    adicionar_breadcrumb @titulo, @conjunto, "conjunto"

    session[:pessoas] = @conjunto.pessoas
  end

  def update
    @titulo = "#{@conjunto.tipo_do_conjunto} #{@conjunto.nome}"
    adicionar_breadcrumb @titulo, @conjunto, "conjunto"

    respond_to do |format|
      if @conjunto.update(conjunto_params)
        if @conjunto.tipo_do_conjunto == "Equipe"
          msg = "Equipe alterada com sucesso"
        else
          msg = "#{@conjunto.tipo.capitalize} alterado com sucesso"
        end
        format.html { redirect_to @conjunto.encontro, notice: msg }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @conjunto.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    tipo_conjunto = @conjunto.tipo_do_conjunto
    if tipo_conjunto == "Equipe"
      texto_notificacao = "Equipe excluída com sucesso"
    else
      texto_notificacao = "#{tipo_conjunto} excluído com sucesso"
    end

    @conjunto.destroy

    session[:notificacao] = texto_notificacao

    respond_to do |format|
      format.html { redirect_to @encontro }
      format.json { head :no_content }
    end
  end

  def adicionar_pessoa_a_conjunto
    precisa_salvar_relacao_pessoa = false

    @conjunto = ConjuntoPessoas.find(params[:id_conjunto])
    @pessoa = Pessoa.find(params[:id_pessoa])

    relacao_pessoa = RelacaoPessoaConjunto.where({:pessoa => @pessoa, :conjunto_pessoas_id => params[:id_conjunto]}).first

    if relacao_pessoa.nil?
      precisa_salvar_relacao_pessoa = true
      relacao_pessoa = RelacaoPessoaConjunto.new({:pessoa => @pessoa, :conjunto_pessoas_id => params[:id_conjunto]})
    end

    if @conjunto.tipo == "Equipe"
      texto_conjunto = "à equipe com sucesso"
    else
      texto_conjunto = "ao #{@conjunto.encontro.denominacao_conjuntos_permanentes.downcase} com sucesso"
    end

    if @pessoa.conjuge.present?
      relacao_conjuge = RelacaoPessoaConjunto.where({:pessoa => @pessoa.conjuge, :conjunto_pessoas_id => params[:id_conjunto]}).first
      if relacao_conjuge.nil?
        precisa_salvar_relacao_conjuge = true
        relacao_conjuge = RelacaoPessoaConjunto.new({:pessoa => @pessoa.conjuge, :conjunto_pessoas_id => params[:id_conjunto]})
      end

      msg_sucesso = "Casal adicionado #{texto_conjunto}"
    else
      msg_sucesso = "Pessoa adicionada #{texto_conjunto}"
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

  def remover_pessoa_de_conjunto
    @conjunto = ConjuntoPessoas.find(params[:id_conjunto])

    condicoes = ["conjunto_pessoas_id = #{@conjunto.id}"]

    @pessoa = Pessoa.find(params[:id_pessoa])
    eh_casal = @pessoa.conjuge.present?

    condicoes_pessoas = ["pessoa_id = #{@pessoa.id}"]
    if eh_casal
      condicoes_pessoas << ["pessoa_id = #{@pessoa.conjuge.id}"]
    end
    condicoes_pessoas = "(#{condicoes_pessoas.join(" OR ")})"

    condicoes << condicoes_pessoas
    condicoes = condicoes.join(" AND ")

    RelacaoPessoaConjunto.where(condicoes).each { |relacao|
      relacao.destroy
    }

    if params[:tipo_conjunto] == "Equipe"
      texto_conjunto = "da equipe"
    else
      texto_conjunto = "do #{params[:tipo_conjunto]}"
    end

    if eh_casal
      msg_sucesso = "Casal removido #{texto_conjunto} com sucesso"
    else
      msg_sucesso = "Pessoa removida #{texto_conjunto} com sucesso"
    end

    numero_pagina = params[:page].to_i
    if @conjunto.pessoas.count < (APP_CONFIG['items_per_page'] * (numero_pagina - 1) + 1)
      numero_pagina -= 1
    end

    respond_to do |format|
      format.json { render json: {novaPagina: numero_pagina, msgSucesso: msg_sucesso}, status: :ok }
    end

  end

  def setar_eh_coordenador
    precisa_salvar_relacao_pessoa = true
    precisa_salvar_relacao_conjuge = false

    pessoa = Pessoa.find(params[:pessoa_id])

    relacao_pessoa = RelacaoPessoaConjunto.where({:pessoa_id => pessoa.id, :conjunto_pessoas_id => params[:conjunto_id]}).first
    relacao_pessoa.eh_coordenador = params[:eh_coordenador]

    if pessoa.conjuge.present?
      relacao_conjuge = RelacaoPessoaConjunto.where({:pessoa_id => pessoa.conjuge.id, :conjunto_pessoas_id => params[:conjunto_id]}).first
      relacao_conjuge.eh_coordenador = params[:eh_coordenador]

      precisa_salvar_relacao_conjuge = true
    end

    if ((precisa_salvar_relacao_pessoa && relacao_pessoa.save) || !precisa_salvar_relacao_pessoa) &&
        ((precisa_salvar_relacao_conjuge && relacao_conjuge.save) || !precisa_salvar_relacao_conjuge)
      render :text => "ok"
    else
      render :text => "erro"
    end
  end

  private

    def set_encontro_grupo_e_conjunto
      if params[:id]
        @conjunto = ConjuntoPessoas.find(params[:id])
        @encontro = @conjunto.encontro
        @grupo = @encontro.grupo
      else
        if params[:encontro_id]
          @encontro = Encontro.find(params[:encontro_id])
          @grupo = @encontro.grupo
        end
      end
    end

    def conjunto_params
      hash = ActionController::Parameters.new(nome: params[:nome], cor_id: params[:cor_id])
      hash.permit!
      return hash
    end

end