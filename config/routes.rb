Noeh::Application.routes.draw do
  scope path_names: { new: 'criar', edit: 'editar' } do
    resources :grupos do
      get 'pessoas/criar', :to => 'pessoas#new', :as => :new_pessoa
      get 'pessoas/:id/editar', :to => 'pessoas#edit', :as => :edit_pessoa
      get 'pessoas/:id', :to => 'pessoas#show', :as => :pessoa

      get 'encontros/padrao', :to => 'encontros#forma_padrao', :as => :padrao
      post 'encontros/padrao', :to => 'encontros#update_forma_padrao', :as => :update_padrao
      resources :encontros, shallow: true
    end
    resources :pessoas
  end

  root :to => 'homepage#index'

  post '/clearnotif', :to => 'homepage#limpar_notificacao', :as => :limpar_notificacao

  get '/deslogado', :to => 'homepage#deslogado', :as => :deslogado

  get '/super_admin', :to => 'super_admin#pagina_inicial', :as => :super_admin_inicial

  post '/log_in', :to => 'sessions#log_in', :as => :log_in
  get '/log_out', :to => 'sessions#log_out', :as => :log_out

  get '/lista_pessoas', :to => 'pessoas#lista_pessoas', :as => :lista_pessoas
  get '/lista_pessoas_js', :to => 'pessoas#lista_pessoas_js', :as => :lista_pessoas_js, :defaults => { :format => 'js' }
  post '/pesquisa_pessoas', :to => 'pessoas#pesquisa_pessoas', :as => :pesquisa_pessoas

  get '/pessoas_no_grupo', :to => 'grupos#pessoas_no_grupo', :as => :pessoas_no_grupo, :defaults => { :format => 'js' }
  post '/setar_coordenador_de_grupo', :to => 'grupos#setar_eh_coordenador', :as => :setar_coordenador_de_grupo
  post '/adicionar_pessoa_a_grupo', :to => 'grupos#adicionar_pessoa_a_grupo', :as => :adicionar_pessoa_a_grupo
  post '/remover_pessoa_de_grupo', :to => 'grupos#remover_pessoa_de_grupo', :as => :remover_pessoa_de_grupo

  get '/equipe/:id', :to => 'conjuntos_pessoas#edit', :as => :equipe
  post '/equipe/:id', :to => 'conjuntos_pessoas#update', :as => :equipe_post
  get '/equipe/:conjunto_id/pessoas/:pessoa_id', :to => 'pessoas#show', :as => :equipe_pessoa

  get '/circulo/:id', :to => 'conjuntos_pessoas#edit', :as => :circulo
  post '/circulo/:id', :to => 'conjuntos_pessoas#update', :as => :circulo_post
  get '/circulo/:conjunto_id/pessoas/:pessoa_id', :to => 'pessoas#show', :as => :circulo_pessoa

  post '/encontros/:encontro_id/equipes/criar', :to => 'conjuntos_pessoas#create', :as => :create_equipe, :tipo_conjunto => 'Equipe'
  post '/encontros/:encontro_id/conjuntos_permanentes/criar', :to => 'conjuntos_pessoas#create', :as => :create_conjunto_permanente, :tipo_conjunto => 'ConjuntoPermanente'
  delete '/conjunto/:id', :to => 'conjuntos_pessoas#destroy', :as => :destroy_conjunto

  post '/setar_coordenador_de_conjunto', :to => 'conjuntos_pessoas#setar_eh_coordenador', :as => :setar_coordenador_de_conjunto
  post '/adicionar_pessoa_a_conjunto', :to => 'conjuntos_pessoas#adicionar_pessoa_a_conjunto', :as => :adicionar_pessoa_a_conjunto
  post '/remover_pessoa_de_conjunto', :to => 'conjuntos_pessoas#remover_pessoa_de_conjunto', :as => :remover_pessoa_de_conjunto

end