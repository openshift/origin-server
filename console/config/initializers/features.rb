Rails.application.config.tap do |config|
  # Support configuring custom cartridges from the UI
  config.custom_cartridges_enabled = Console.config.env(:CUSTOM_CARTRIDGES_ENABLED, true)
end