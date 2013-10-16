require File.expand_path('../../test_helper', __FILE__)

class BootstrapFormBuilderTest < ActiveSupport::TestCase

  setup do
    @template = Object.new
    @form_helper = Console::Formtastic::BootstrapFormBuilder.new(nil,nil,@template,{},nil)
  end

  test "error list concatenation" do
    assert_concatenates_to '', []

    assert_concatenates_to "A.", ["A"]
    assert_concatenates_to "A.", ["A."]
    assert_concatenates_to "A.", ["A. "]
    assert_concatenates_to "A.", [" A. "]

    assert_concatenates_to "A. B.", ["A", "B"]
    assert_concatenates_to "A. B.", ["A.", "B"]
    assert_concatenates_to "A. B.", ["A. ", "B"]
    assert_concatenates_to "A. B.", ["A. ", "B."]
    assert_concatenates_to "A. B.", ["A. ", "B. "]
    assert_concatenates_to "A. B.", ["A. ", " B. "]

    assert_concatenates_to "A. B.", [["A"], ["B"]]
  end

  protected
    def assert_concatenates_to(str, errors)
      @template.expects(:content_tag).with(:p, str, {:class => 'help-inline'}).returns(str)
      assert_equal str, @form_helper.error_list(errors)
    end
end
