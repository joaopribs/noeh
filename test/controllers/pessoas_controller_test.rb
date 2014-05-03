require 'test_helper'

class PessoasControllerTest < ActionController::TestCase
  setup do
    @membro = pessoas(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pessoas)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pessoa" do
    assert_difference('Pessoa.count') do
      post :create, membro: {  }
    end

    assert_redirected_to pessoa_path(assigns(:membro))
  end

  test "should show pessoa" do
    get :show, id: @membro
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @membro
    assert_response :success
  end

  test "should update pessoa" do
    patch :update, id: @membro, membro: {  }
    assert_redirected_to pessoa_path(assigns(:membro))
  end

  test "should destroy pessoa" do
    assert_difference('Pessoa.count', -1) do
      delete :destroy, id: @membro
    end

    assert_redirected_to pessoas_path
  end
end
