Noeh::Application.routes.draw do
  match '/pessoas/pesquisar', :to => 'pessoas#pesquisar_pessoas', :as => :pesquisar_pessoas, via: [:get, :post]

  scope path_names: { new: 'criar', edit: 'editar' } do
    resources :grupos do
      get 'pessoas/criar', :to => 'pessoas#new', :as => :new_pessoa
      get 'pessoas/:id/editar', :to => 'pessoas#edit', :as => :edit_pessoa
      get 'pessoas/:id', :to => 'pessoas#show', :as => :pessoa

      get 'ex-participantes', :to => 'grupos#ex_participantes', :as => :ex_participantes

      get 'encontros/padrao', :to => 'encontros#forma_padrao', :as => :padrao
      post 'encontros/padrao', :to => 'encontros#update_forma_padrao', :as => :update_padrao
      resources :encontros, shallow: true do
        get 'coordenadores', :to => 'conjuntos_pessoas#editar_coordenadores_de_encontro', :as => :editar_coordenadores
        get 'coordenadores/pessoas/criar', :to => 'pessoas#new', :as => :coordenadores_criar_pessoa
        get 'coordenadores/pessoas/:id', :to => 'pessoas#show', :as => :coordenadores_pessoa
        get 'coordenadores/pessoas/:id/editar', :to => 'pessoas#edit', :as => :coordenadores_pessoa_editar
      end
    end
    resources :pessoas
  end

  root :to => 'homepage#index'

  post '/clearnotif', :to => 'homepage#limpar_notificacao', :as => :limpar_notificacao

  get '/deslogado', :to => 'homepage#deslogado', :as => :deslogado

  post '/log_in', :to => 'sessions#log_in', :as => :log_in
  post '/login_com_id', :to => 'sessions#login_com_id', :as => :login_com_id
  get '/log_out', :to => 'sessions#log_out', :as => :log_out

  get '/lista_pessoas', :to => 'pessoas#lista_pessoas', :as => :lista_pessoas
  get '/lista_pessoas_js', :to => 'pessoas#lista_pessoas_js', :as => :lista_pessoas_js, :defaults => { :format => 'js' }
  post '/pesquisa_pessoas_por_nome', :to => 'pessoas#pesquisa_pessoas_por_nome', :as => :pesquisa_pessoas_por_nome
  post '/filtrar_pessoas', :to => 'pessoas#filtrar_pessoas', :as => :filtrar_pessoas

  get '/pessoas_no_grupo', :to => 'grupos#pessoas_no_grupo', :as => :pessoas_no_grupo, :defaults => { :format => 'js' }
  post '/setar_coordenador_de_grupo', :to => 'grupos#setar_eh_coordenador', :as => :setar_coordenador_de_grupo
  post '/adicionar_pessoa_a_grupo', :to => 'grupos#adicionar_pessoa_a_grupo', :as => :adicionar_pessoa_a_grupo
  post '/remover_pessoa_de_grupo', :to => 'grupos#remover_pessoa_de_grupo', :as => :remover_pessoa_de_grupo

  get '/encontros_de_grupo', :to => 'grupos#encontros_de_grupo', :as => :encontros_de_grupo, :defaults => { :format => 'js' }
  get '/conjuntos_para_adicionar_pessoa', :to => 'conjuntos_pessoas#conjuntos_para_adicionar_pessoa', :as => :conjuntos_para_adicionar_pessoa, :defaults => { :format => 'js' }

  get '/encontro/:encontro_id/coordenadores', :to => 'conjuntos_pessoas#editar_coordenadores_de_encontro', :as => :coordenacao_encontro

  get '/equipe/:id', :to => 'conjuntos_pessoas#edit', :as => :equipe
  post '/equipe/:id', :to => 'conjuntos_pessoas#update', :as => :equipe_post
  get '/equipe/:conjunto_id/pessoas/criar', :to => 'pessoas#new', :as => :equipe_criar_pessoa
  get '/equipe/:conjunto_id/pessoas/:id', :to => 'pessoas#show', :as => :equipe_pessoa
  get '/equipe/:conjunto_id/pessoas/:id/editar', :to => 'pessoas#edit', :as => :equipe_pessoa_editar
  post '/equipe/:id/upload_relatorio', :to => 'conjuntos_pessoas#upload_relatorio', :as => :upload_relatorio
  post '/equipe/:id/remover_relatorio', :to => 'conjuntos_pessoas#remover_relatorio', :as => :remover_relatorio

  get '/circulo/:id', :to => 'conjuntos_pessoas#edit', :as => :circulo
  post '/circulo/:id', :to => 'conjuntos_pessoas#update', :as => :circulo_post
  get '/circulo/:conjunto_id/pessoas/criar', :to => 'pessoas#new', :as => :circulo_criar_pessoa
  get '/circulo/:conjunto_id/pessoas/:id', :to => 'pessoas#show', :as => :circulo_pessoa
  get '/circulo/:conjunto_id/pessoas/:id/editar', :to => 'pessoas#edit', :as => :circulo_pessoa_editar
  get '/circulo/:id/recomendacoes', :to => 'conjuntos_pessoas#recomendacoes', :as => :recomendacoes
  post '/circulo/:id/recomendacoes', :to => 'conjuntos_pessoas#recomendacoes', :as => :recomendacoes_post

  post '/encontros/:encontro_id/equipes/criar', :to => 'conjuntos_pessoas#create', :as => :create_equipe, :tipo_conjunto => 'Equipe'
  post '/encontros/:encontro_id/conjuntos_permanentes/criar', :to => 'conjuntos_pessoas#create', :as => :create_conjunto_permanente, :tipo_conjunto => 'ConjuntoPermanente'
  delete '/conjunto/:id', :to => 'conjuntos_pessoas#destroy', :as => :destroy_conjunto

  post '/setar_coordenador_de_conjunto', :to => 'conjuntos_pessoas#setar_eh_coordenador', :as => :setar_coordenador_de_conjunto
  post '/adicionar_pessoa_a_conjunto', :to => 'conjuntos_pessoas#adicionar_pessoa_a_conjunto', :as => :adicionar_pessoa_a_conjunto
  post '/remover_pessoa_de_conjunto', :to => 'conjuntos_pessoas#remover_pessoa_de_conjunto', :as => :remover_pessoa_de_conjunto

  get '/cadastrar', :to => 'pessoas#cadastrar_novo', :as => :cadastrar_novo
  get '/confirmacao_cadastro', :to => 'pessoas#cadastrar_novo_confirmacao', :as => :cadastrar_novo_confirmacao

  get '/privacidade', :to => 'homepage#privacidade', :as => :privacidade

  post '/confirmar_participacao', :to => 'pessoas#confirmar_auto_sugestao', :as => :confirmar_auto_sugestao
  post '/rejeitar_participacao', :to => 'pessoas#rejeitar_auto_sugestao', :as => :rejeitar_auto_sugestao
  get '/pessoas_confirmar', :to => 'pessoas#pessoas_a_confirmar', :as => :pessoas_a_confirmar

  post '/pegar_informacoes_facebook_pelo_link', :to => 'application#pegar_informacoes_facebook_pelo_link', :as => :pegar_informacoes_facebook_pelo_link

  get 'mobile/deslogado', :to => 'mobile#deslogado', :as => :mobile_deslogado
  get 'mobile/nao_cadastrado', :to => 'mobile#nao_cadastrado', :as => :mobile_nao_cadastrado
  get 'mobile/index', :to => 'mobile#index', :as => :mobile_index
  get 'mobile/pessoa/:id', :to => 'mobile#pessoa', :as => :mobile_pessoa
  get 'mobile/conjunto/:id', :to => 'mobile#conjunto', :as => :mobile_conjunto
  get 'mobile/encontro/:id', :to => 'mobile#encontro', :as => :mobile_encontro
  get 'mobile/grupo/:id', :to => 'mobile#grupo', :as => :mobile_grupo
  match 'mobile/pesquisar_pessoas', :to => 'mobile#pesquisar_pessoas', :as => :mobile_pesquisar_pessoas, via: [:get, :post]


  post '/pegar_usuario_facebook', :to => 'sessions#pegar_usuario_facebook', :as => :pegar_usuario_facebook
  get '/teste', :to => 'homepage#teste', :as => :teste

end