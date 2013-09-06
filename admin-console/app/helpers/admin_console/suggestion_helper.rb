module AdminConsole
  module SuggestionHelper

    def suggestion_partial_for(suggestion)
      klass = suggestion.is_a?(Class) ? suggestion : suggestion.class
      "admin_console/suggestions/#{klass.to_s.gsub(/^Admin::Suggestion::/,"").underscore}"
    end
  end
end