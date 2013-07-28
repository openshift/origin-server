require 'openshift-origin-node/model/cartridge_repository'

Before('@manipulates_cart_repo') do 
  clean_cart_repo
end

After('@manipulates_cart_repo') do
  clean_cart_repo
end

def clean_cart_repo
  cart_repo = OpenShift::Runtime::CartridgeRepository.instance

  check_carts = ['mock', 'mock-plugin']

  restart_mcollectived = false

  check_carts.each do |cart|
    if cart_repo.exist?(cart, '0.0.2', '0.1')
      $logger.info('Erasing test-generated version mock-0.1')
      cart_repo.erase(cart, '0.1', '0.0.2')

      restart_mcollectived = true
    end
  end

  %x(service mcollective restart) if restart_mcollectived

  sleep 5

  cart_repo.clear
  cart_repo.load
end
