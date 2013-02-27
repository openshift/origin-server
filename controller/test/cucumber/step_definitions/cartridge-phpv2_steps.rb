Then /^the php cartridge private endpoints will be exposed$/ do
  app_env_var_will_exist('PHP_IP')
  app_env_var_will_exist('PHP_PORT')
end
