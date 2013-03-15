Then /^the diy-0.1 cartridge private endpoints will be exposed$/ do
  app_env_var_will_exist('DIY_IP')
  app_env_var_will_exist('DIY_PORT')
end
