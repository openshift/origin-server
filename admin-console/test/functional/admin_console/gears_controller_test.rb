require File.expand_path('../../../test_helper', __FILE__)

module AdminConsole
  class GearsControllerTest < ActionController::TestCase
    def setup    
      @random = rand(1000000000)
    end

    test "should show gear not found" do
      gear_id = "does_not_exist#{@random}"
      get :show, :id => gear_id
      assert_not_found_page "Gear #{gear_id} not found"
    end
    
  end
end
