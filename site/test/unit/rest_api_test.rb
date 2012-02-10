require 'test_helper'

class RestApiTest < ActiveSupport::TestCase

  def setup
    #TODO
    #@user = WebUser.new
    #@user.authenticate(gen_small_uuid,'secret')
  end

  def create_domain_if_none
    #TODO: Verify that api to create domain without ssh key is present on broker
    #@domain = Domain.first :as => @user
    #unless @domain
    #  @domain = Domain.new :namespace => gen_small_uuid, :as => @user
    #  @domain.save
    #  #assert @domain.errors.empty?
    #end
  end

  test "user should be successfully retrieved" do
    #user = User.find :one, :as => @user
    #assert_equal user.login, @user.login
  end

  test "ssh keys should be successfully retrieved" do
    #TODO
    #items = Key.find :all, :as => @user
    #assert items.is_a? Array
  end

  test "domains should be successfully retrieved" do
    #TODO:
    #create_domain_if_none
    #domains = Domain.find :all, :as => @user
    #assert domains.is_a? Array
    #assert_equal 1, domains.length
  end

end
