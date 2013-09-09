require File.expand_path('../../../test_helper', __FILE__)

module AdminConsole
  class WebFlowsTest < ActionDispatch::IntegrationTest
    web_integration

    test "admin console overview and profile summary render" do
      visit admin_console_path

      assert has_css?("h1"), "System Capacity"

      nodes = all(".nodes").first

      nodes.click

      assert has_css?(".profile-full-page")

      node = all(".node").first

      node.click

      assert has_css?("h1", "Node")
      assert has_css?("h1 .icon")
    end

    test "admin console nav search bar" do
      visit admin_console_path

      find(".search-query").set("user_with_multiple_gear_sizes@test.com")
      find('.navbar-search button[type="submit"]').click

      assert has_css?("h1", "user_with_multiple_gear_sizes@test.com")
    end

    test "admin console application navigation flow" do
      app = with_app

      visit "/admin-console/applications/#{app.uuid}"

      assert has_css?("h1", "#{app.name}")

      find("a", :text => "#{app.domain.owner.login}").click

      assert has_css?("h1", "#{app.domain.owner.login}")

      find("a", :text => "#{app.fqdn}").click

      assert has_css?("h1", "#{app.name}")

      find("a", :text => "#{app.group_instances[0].gears[0].uuid}").click

      assert has_css?("h1", "#{app.group_instances[0].gears[0].uuid}")

      find("a", :text => "#{app.group_instances[0].gears[0].server_identity}").click

      assert has_css?("h1", "#{app.group_instances[0].gears[0].server_identity}")
    end
  end
end