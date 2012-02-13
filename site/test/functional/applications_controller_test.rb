require 'test_helper'

class ApplicationsControllerTest < ActionController::TestCase
  test "should get new unauthorized" do
    get :new
    assert_response :success
  end

  test "should retrieve application list" do
    return unless Rails.configuration.integrated
    setup_session
    get(:show)
    assert assigns(:applications)
    assert_response :success
  end

  test "should check for empty name" do
    form = get_post_form
    form[:name]=''
    post(:create, {:application => form})
    assert assigns(:application)
    assert assigns(:application).errors[:name].length > 0
    assert_response :success
  end

  test "should redirect on success" do
    post(:create, :application => get_post_form)
    assert assigns(:application)
    assert assigns(:application).errors.empty?
    assert_redirected_to :action => 'show'
    assert_template
  end

  def get_post_form
    {:name => 'test1', :application_type => 'empty'}
  end
end
