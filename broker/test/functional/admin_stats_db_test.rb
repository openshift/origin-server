ENV["TEST_NAME"] = "admin_stats_db_test"
# Although there's no controller that uses Admin::Stats, we need some
# applications in the DB to test that its parsing of mongo documents
# is working. So, we'll use functional test techniques to create those
# and then test that Stats doesn't choke on anything.
require 'test_helper'
class AdminStatsDbTest < ActionController::TestCase

  # yanked almost verbatim from application_test.rb
  def setup
    @controller = ApplicationsController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.save
    Lock.create_lock(@user.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    stubber
    @namespace = "ns#{@random}"
    @domain = Domain.new(namespace: @namespace, owner:@user)
    @domain.save
  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "create some apps and check that stats work out" do
    # create a PHP app
    php_app = "app#{@random}php"
    post :create, {"name" => php_app, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :created
    # Add other apps with problematic data to test

    begin
      # run some stats assuming the created app(s)
      stats = Admin::Stats::Maker.new
      c = {}
      assert_nothing_raised { c[:all], c[:profile], c[:user] = stats.get_db_stats }
      assert c[:all][:apps] >= 1, "number of apps should be at least what we created"
      assert c[:all][:users_with_num_apps][1] >= 1,
        "number of users with our user's number of apps should be at least 1"
      assert c[:all][:cartridges_short]['php'] >= 1,
        "number of php carts should be at least what we created"
      assert c[:user].has_key?(@login), "our user should be in the results"

    ensure
      # delete any apps created
      delete :destroy , {"id" => php_app, "domain_id" => @domain.namespace}
      assert_response :ok
    end
  end
end
