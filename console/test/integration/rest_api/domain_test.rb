require File.expand_path('../../../test_helper', __FILE__)

class RestApiDomainTest < ActiveSupport::TestCase
  include RestApiAuth

  def setup
    with_configured_user
  end
  def teardown
    cleanup_domain
  end

  def test_load_setup_domain
    setup_domain
    setup_domain
    assert @domain
    assert @domain.errors.empty?
  end

  def test_domains_get
    setup_domain
    domains = Domain.find :all, :as => @user
    assert_equal 1, domains.length
    assert_equal "#{uuid}", domains[0].name
  end

  def test_domains_first
    setup_domain
    domain = Domain.find :one, :as => @user
    assert_equal "#{uuid}", domain.name
  end

  def test_domain_exists_error
    setup_domain
    domain = Domain.find :one, :as => @user
    domain2 = Domain.new :name => domain.name, :as => @user
    assert !domain2.save
    assert domain2.errors[:name].is_a?(Array), domain2.errors.inspect
    assert domain2.errors[:name][0].is_a?(String), domain2.errors.inspect
    assert domain2.errors[:name][0].include?('Name'), domain2.errors[:name][0]
  end

  def test_domains_update
    setup_domain
    domains = Domain.find :all, :as => @user
    assert_equal 1, domains.length
    assert_equal "#{uuid}", domains[0].name

    d = domains[0]
    assert !d.changed?
    assert_equal "#{uuid}", d.id

    # change name twice to make sure id doesn't change
    d.name = "notsaved"
    assert d.changed?
    assert_equal "#{uuid}", d.to_param
    d.name = "#{uuid.reverse}"
    assert_equal "#{uuid}", d.to_param

    assert d.save, d.errors.inspect
    assert !d.changed?
    # make sure the param value == the current name
    assert_equal "#{uuid.reverse}", d.to_param

    domains = Domain.find :all, :as => @user
    assert_equal 1, domains.length
    assert_equal "#{uuid.reverse}", domains[0].name

    #cleanup
    domains.each {|d| d.destroy_recursive}
    @domain = nil
  end

  def test_domain_delete
    setup_domain
    domain = @domain
    name = domain.name

    assert_difference('Domain.find(:all, :as => @user).length', -1) do
      assert domain.destroy
    end

    @domain = nil # don't need to clear the first domain now
  end

  def test_domain_find_throws
    assert_raise RestApi::ResourceNotFound do
      Domain.find 'invalid_name', :as => @user
    end
  end
end
