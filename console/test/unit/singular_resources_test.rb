require File.expand_path('../../test_helper', __FILE__)

class SingularResourcesTest < ActiveSupport::TestCase
  teardown{ Rails.application.reload_routes! }
  test "singluar resources route generation" do
    Rails.application.routes.draw{ resources :foos, :singular_resource => true }
    assert_equal "/foo/:id/edit(.:format)", "#{Rails.application.routes.named_routes.routes[:edit_foo].path.spec}"
    assert_equal "/foos/new(.:format)", "#{Rails.application.routes.named_routes.routes[:new_foo].path.spec}"
  end
end