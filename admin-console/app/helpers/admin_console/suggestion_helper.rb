module AdminConsole
  module SuggestionHelper

    def suggestion_partial_for(suggestion)
      klass = suggestion.is_a?(Class) ? suggestion : suggestion.class
      return 'admin_console/suggestions/' + Hash.new('generic').merge({
        Admin::Suggestion::Error => 'error',
        Admin::Suggestion::Capacity::Add => 'cap_add',
        Admin::Suggestion::Capacity::Remove::Node => 'cap_remove_node',
        Admin::Suggestion::Capacity::Remove::CompactDistrict  => 'cap_remove_compact',
        Admin::Suggestion::MissingNodes => 'missing_nodes',
        Admin::Suggestion::Config::FixVal => 'conf_fix_val',
        Admin::Suggestion::Config::FixGearDown => 'conf_gear_down',
      })[klass]
    end
  end
end