module AdminConsole
  module SuggestionHelper

    def suggestion_partial_for(suggestion)
      klass = suggestion.is_a?(Class) ? suggestion : suggestion.class
      return 'admin_console/suggestions/' + Hash.new('generic').merge({
        Admin::Suggestion::Error => 'error',
        Admin::Suggestion::Capacity::Add::Node => 'cap_add_node',
      })[klass]
    end
  end
end

