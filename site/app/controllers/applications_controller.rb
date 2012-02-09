class ApplicationsController < ApplicationController
  def new
    types = ApplicationType.find :all
    @framework_types, @application_types = types.partition { |t| t.categories.include?(:framework) }
    Rails.logger.debug "App types #{@application_types.inspect} #{@application_types.empty?}"
  end
end
