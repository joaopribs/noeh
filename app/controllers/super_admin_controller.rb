class SuperAdminController < ApplicationController

  def pagina_inicial
    precisa_ser_super_admin
  end

end