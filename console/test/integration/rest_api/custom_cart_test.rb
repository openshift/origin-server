require File.expand_path('../../../test_helper', __FILE__)

class RestApiCustomCartTest < ActiveSupport::TestCase
  include RestApiAuth

  def test_create_app_from_rediscart
    with_configured_user
    setup_domain

    assert_create_app({:include => :cartridges, :initial_git_url => 'empty', :cartridges => ['php-5.3', {:url => 'https://rediscart-claytondev.rhcloud.com'}]}, "Create an app with Redis") do |app|
      loaded_app = Application.find(:one, :params => {:name => app.name, :domain_id => @domain.id}, :as => @user)
      assert loaded_app.cartridges.map(&:name).one?{ |s| s =~ /smarterclayton-redis-/ }
    end
  end

  def test_create_app_from_cdk
    with_configured_user
    setup_domain

    assert_create_app({:include => :cartridges, :initial_git_url => 'empty', :cartridges => [{:url => 'https://cdk-claytondev.rhcloud.com'}]}, "Create an app based on the CDK") do |app|
      loaded_app = Application.find(:one, :params => {:name => app.name, :domain_id => @domain.id}, :as => @user)
      assert loaded_app.cartridges.map(&:name).one?{ |s| s =~ /smarterclayton-cdk-/ }
    end
  end

  def test_create_failing_app_from_cdk
    with_configured_user
    setup_domain

    assert_create_app_fails({:include => :cartridges, :cartridges => [{:url => 'https://cdk-claytondev.rhcloud.com/manifest/failure'}]}, "Create an app based on the CDK") do |app|
      assert app.errors.to_hash[:base].any? {|e| e =~ /Failed to execute: 'control start'/}
    end
  end

  def test_custom_cart_with_bad_control_script_fails
    with_configured_user
    setup_domain
    assert_create_app_fails({:include => :cartridges, :cartridges => [{:url => 'https://cdk-claytondev.rhcloud.com/manifest/failure'}]}, "Create an app with a failing cartridge control script") do |app|
      #assert app.errors.full_messages.one?{ |m| m =~ /Unable to complete the requested operation/ }, app.errors.inspect
      assert app.errors.full_messages.one?{ |m| m.include? "Failed to execute: 'control start'" }, app.errors.inspect
    end
  end

  def test_custom_cart_with_bad_control_script_gets_output
    with_configured_user
    setup_domain
    assert_create_app_fails({:include => :cartridges, :cartridges => [{:url => 'https://cdk-claytondev.rhcloud.com/manifest/failure_output'}]}, "Create an app with a failing cartridge control script and output") do |app|
      assert app.errors.full_messages.one?{ |m| m =~ /Stderr output/ }, app.errors.inspect
      assert app.errors.full_messages.any?{ |m| m =~ /Deliberate failure/ }, app.errors.inspect
      assert app.errors.full_messages.one?{ |m| m.include? "Failed to execute: 'control start'" }, app.errors.inspect
    end
  end

  def assert_create_app(options, message="", &block)
    app = Application.new({:name => 'test', :domain => @domain}.merge(options))
    assert app.save, "#{app.name} could not be saved, #{app.errors.to_hash.inspect}"
    begin
      yield app
    ensure
      (app.destroy rescue puts "Unable to delete app" if app.persisted?)
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
      (app.destroy rescue puts "Unable to delete app") if app.persisted? 
    end
    app
  end  
end
