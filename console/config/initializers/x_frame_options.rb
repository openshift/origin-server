#
# Backport use of X-Frame-Options in Rails 4.0 https://github.com/rails/rails/issues/6311
#
# Remove on upgrade.
#
class ActionDispatch::Response < Rack::Response
  cattr_accessor(:default_x_frame_options)

  def to_a
    assign_default_content_type_and_charset!
    handle_conditional_get!
    self["Set-Cookie"] = self["Set-Cookie"].join("\n") if self["Set-Cookie"].respond_to?(:join)
    self["ETag"]       = @_etag if @_etag
    if !self.class.default_x_frame_options.nil?
      self["X-Frame-Options"] ||= self.class.default_x_frame_options
    end
    super
  end
end

config = Rails.application.config
config.action_dispatch.x_frame_options ||= 'SAMEORIGIN'

if config.action_dispatch.x_frame_options
  ActionDispatch::Response.default_x_frame_options = config.action_dispatch.x_frame_options
end

raise "Code needs upgrade for rails 3.1+" if Rails.version[0..3] != '3.0.'
