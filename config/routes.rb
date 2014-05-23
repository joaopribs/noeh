Noeh::Application.routes.draw do
  scope path_names: { new: 'criar', edit: 'editar' } do
    resources :grupos
    resources :pessoas
  end

  root :to => 'homepage#index'

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

  post '/notif', :to => 'homepage#limpar_notificacao', :as => :limpar_notificacao

end