require 'rubygems'
require 'uri'
require 'fileutils'

include AppHelper

Given /^a new client created (.+) application OLD$/ do |type|
  @app = TestApp.create_unique(type)
  register_user(@app.login, @app.password) if $registration_required
  if rhc_create_domain_old(@app)
    rhc_create_app_old(@app)
  end
end

When /^(\d+) (.+) applications are created OLD$/ do |app_count, type|
  # Create our domain and apps
  @apps = app_count.to_i.times.collect do
    app = TestApp.create_unique(type)
    register_user(app.login, app.password) if $registration_required
    if rhc_create_domain_old(app)
      rhc_create_app_old(app)
    end
    app
  end
end

When /^the embedded (.*) cartridge is added OLD$/ do |type|
  rhc_embed_add_old(@app, type)
end

When /^the embedded (.*) cartridge is removed OLD$/ do |type|
  rhc_embed_remove_old(@app, type)
end

When /^the application is stopped OLD$/ do
  rhc_ctl_stop_old(@app)
end

When /^the application is started OLD$/ do
  rhc_ctl_start_old(@app)
end

When /^the application is aliased OLD$/ do
  rhc_add_alias_old(@app)
end

When /^the application is unaliased OLD$/ do
  rhc_remove_alias(@app)
end

When /^the application is restarted OLD$/ do
  rhc_ctl_restart_old(@app)
end

When /^the application is destroyed OLD$/ do
  rhc_ctl_destroy_old(@app)
end

When /^the application namespace is updated OLD$/ do
  rhc_update_namespace_old(@app)
end

When /^I snapshot the application OLD$/ do
  rhc_snapshot_old(@app)
end

When /^I tidy the application OLD$/ do
  rhc_tidy_old(@app)
end

When /^I restore the application OLD$/ do
  rhc_restore_old(@app)
end
