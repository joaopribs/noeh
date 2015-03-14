class MobileController < ApplicationController
  skip_before_filter :precisa_estar_logado, :only => :deslogado
  skip_before_filter :nao_pode_ser_mobile

  layout 'mobile'

  def deslogado
    render layout: false
  end

  def nao_cadastrado
  end

  def index
    redirect_to mobile_pessoa_url(@usuario_logado)
  end

  def pessoa
    @pessoa = Pessoa.unscoped.find(params[:id])

    precisa_poder_ver_pessoa(@pessoa)
    return if performed?

    @participacoes = (@pessoa.conjuntos_permanentes + @pessoa.equipes).select{|c| @usuario_logado.permissoes.pode_ver_participacao(c, @pessoa)}

    if @pessoa.conjuge.present?
      @participacoes_conjuge = (@pessoa.conjuge.conjuntos_permanentes + @pessoa.conjuge.equipes).select{|c| @usuario_logado.permissoes.pode_ver_participacao(c, @pessoa)}
      @participacoes_conjuge = @participacoes_conjuge.sort_by!{|c| c.encontro.data_inicio}.reverse
    end
    
    @participacoes = @participacoes.sort_by!{|c| c.encontro.data_inicio}.reverse
  end

  def conjunto
    @conjunto = ConjuntoPessoas.find(params[:id])

    precisa_poder_gerenciar_conjunto(@conjunto)
    return if performed?
  end

  private 

    def precisa_poder_ver_pessoa pessoa
      if pessoa.conjuge.present?
        if !@usuario_logado.permissoes.pode_ver_pessoa(pessoa) && !@usuario_logado.permissoes.pode_ver_pessoa(pessoa.conjuge)
          redirect_to mobile_index_url and return
        end
      else
        if !@usuario_logado.permissoes.pode_ver_pessoa(pessoa)
          redirect_to mobile_index_url and return
        end
      end
    end

    def precisa_poder_gerenciar_conjunto conjunto
      if !@usuario_logado.permissoes.pode_gerenciar_conjunto(conjunto)
        redirect_to root_url and return
      end
    end
end