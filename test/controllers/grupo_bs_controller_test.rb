require 'test_helper'

class GrupoBsControllerTest < ActionController::TestCase
  setup do
    @grupo_b = grupo_bs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:grupo_bs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create grupo_b" do
    assert_difference('GrupoB.count') do
      post :create, grupo_b: { nome: @grupo_b.nome }
    end

    assert_redirected_to grupo_b_path(assigns(:grupo_b))
  end

  test "should show grupo_b" do
    get :show, id: @grupo_b
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @grupo_b
    assert_response :success
  end

  test "should update grupo_b" do
    patch :update, id: @grupo_b, grupo_b: { nome: @grupo_b.nome }
    assert_redirected_to grupo_b_path(assigns(:grupo_b))
  end

  test "should destroy grupo_b" do
    assert_difference('GrupoB.count', -1) do
      delete :destroy, id: @grupo_b
    end

    assert_redirected_to grupo_bs_path
  end
end
