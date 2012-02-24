require 'test_helper'

class KeysControllerTest < ActionController::TestCase

  @@setup = false

  def setup
    setup_integrated(false)
    unless @@setup
      @@setup = true
      domain = Domain.first :as => @user
      domain.destroy_recursive if domain
      setup_domain
    end
  end
  def teardown
  end

  @name = 0
  def unique_name
    "#{self.class.next}key"
  end
  def self.next
    @name += 1
  end

  test "should create key" do
    post :create, {:key => get_post_form}

    assert key = assigns(:key)
    assert key.errors.empty?, key.errors.inspect
    assert_redirected_to account_path

    assert key.destroy
  end

  test "should create key and redirect back" do
    @request.env['HTTP_REFERER'] = 'http://arbitrary/back'

    post :create, {:key => get_post_form, :first => true}

    assert key = assigns(:key)
    assert key.errors.empty?, key.errors.inspect
    assert_redirected_to 'http://arbitrary/back'
    assert flash[:success]

    assert key.destroy
  end

  test "should create key and redirect back without referrer" do
    post :create, {:key => get_post_form, :first => true}

    assert key = assigns(:key)
    assert key.errors.empty?, key.errors.inspect
    assert_redirected_to account_path
    assert flash[:success]

    assert key.destroy
  end

  test "should overwrite default key" do
    (key = Key.new(:name => 'default', :raw_content => 'ssh-rsa abc1', :as => @user)).save!

    post :create, {:key => {:name => 'default', :raw_content => 'ssh-rsa abc2'}, :first => true}

    assert key = assigns(:key)
    assert_equal 'abc2', key.content
    assert key.errors.empty?, key.errors.inspect
    assert_redirected_to account_path
    assert flash[:success]

    assert key.destroy
  end

  test "should give key new name" do
    (key = Key.new(:name => 'test', :raw_content => 'ssh-rsa abc1', :as => @user)).save!

    post :create, {:key => {:name => 'test', :raw_content => 'ssh-rsa abc2'}, :first => true}

    assert key = assigns(:key)
    assert_equal 'test2', key.name
    assert_equal 'abc2', key.content
    assert key.errors.empty?, keys.errors.inspect
    assert_redirected_to account_path
    assert flash[:success]

    assert key.destroy
  end

  test "should destroy key" do
    (key = Key.new(get_post_form.merge(:as => @user))).save!

    delete :destroy, :id => key.id
    assert_redirected_to account_path
  end

  test "should assign errors on empty name" do
    post :create, {:key => get_post_form.merge(:name => '')}

    assert key = assigns(:key)
    assert !key.errors.empty?
    assert key.errors[:name].present?, key.errors.inspect
    assert_equal 1, key.errors[:name].length
    assert_template :new
  end

  test "should assign errors on long name" do
    post :create, {:key => get_post_form.merge(:name => 'aoeu'*100)}

    assert key = assigns(:key)
    assert !key.errors.empty?
    assert key.errors[:name].present?, key.errors.inspect
    assert_equal 1, key.errors[:name].length
    assert_template :new
  end

  test "should assign errors on invalid name" do
    post :create, {:key => get_post_form.merge(:name => '@@@@')}

    assert key = assigns(:key)
    assert !key.errors.empty?
    assert key.errors[:name].present?, key.errors.inspect
    assert_equal 1, key.errors[:name].length
    assert_template :new
  end

  test "should assign errors on duplicate name" do
    (key = Key.new(get_post_form.merge(:as => @user))).save!

    post :create, {:key => get_post_form.merge(:name => key.name, :raw_content => 'ssh-rsa XYZ')}
    assert key = assigns(:key)
    assert !key.errors.empty?
    assert key.errors[:name].present?, key.errors.inspect
    assert_equal 1, key.errors[:name].length
    assert_template :new
  end

  test "should assign errors on duplicate content" do
    (key = Key.new get_post_form.merge(:as => @user)).save!

    #FIXME failing deliberately due to 409 conflict
    post :create, {:key => get_post_form.merge(:name => unique_name, :raw_content => 'ssh-rsa nossh')}
    assert key = assigns(:key)
    assert !key.errors.empty?
    assert key.errors[:raw_content].present?, key.errors.inspect
    assert_equal 1, key.errors[:raw_content].length
    assert_template :new
  end

  def get_post_form
    {:name => unique_name, :raw_content => 'ssh-rsa nossh'}
  end
end
