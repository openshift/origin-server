require File.expand_path('../../../test_helper', __FILE__)

class RestApiCustomCartTest < ActiveSupport::TestCase
  include RestApiAuth

  def test_create_app_from_rediscart
    with_configured_user
    setup_domain

    assert_create_app({:include => :cartridges, :initial_git_url => 'empty', :cartridges => ['php-5.3', 'https://rediscart-claytondev.rhcloud.com']}, "Create an app with Redis") do |app|
      loaded_app = Application.find(app.name, :params => {:domain_id => @domain.id}, :as => @user)
      assert loaded_app.cartridges.map(&:name).one?{ |s| s =~ /smarterclayton-redis-/ }
    end
  end

  def test_create_app_from_cdk
    with_configured_user
    setup_domain

    assert_create_app({:include => :cartridges, :initial_git_url => 'empty', :cartridges => ['php-5.3', 'https://cdk-claytondev.rhcloud.com']}, "Create an app based on the CDK") do |app|
      loaded_app = Application.find(app.name, :params => {:domain_id => @domain.id}, :as => @user)
      assert loaded_app.cartridges.map(&:name).one?{ |s| s =~ /smarterclayton-cdk-/ }
    end
  end

  def assert_create_app(options, message="", &block)
    app = Application.new({:name => 'test', :domain => @domain}.merge(options))
    assert app.save, "#{app.name} could not be saved, #{app.errors.to_hash.inspect}"
    begin
      yield app
    ensure
      puts "Unable to delete app" unless app.destroy
    end
    app
  end

  def assert_create_app_fails(options, message="", &block)
    app = Application.new({:name => 'test', :domain => @domain}.merge(options))
    begin
      assert !app.save, "#{app.name} was saved incorrectly"
      assert !app.persisted?
      yield app
    ensure
      puts "Unable to delete app" unless !app.persisted? || app.destroy
    end
    app
  end  
end
