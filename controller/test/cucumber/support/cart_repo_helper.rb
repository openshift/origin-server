require 'openshift-origin-node/model/cartridge_repository'

Before('@manipulates_cart_repo') do 
  clean_cart_repo
end

After('@manipulates_cart_repo') do
  clean_cart_repo
end

def clean_cart_repo
  cart_repo = OpenShift::Runtime::CartridgeRepository.instance

  if cart_repo.exist?('mock', '0.0.2', '0.1')
    $logger.info('Erasing test-generated version mock-0.1')
    cart_repo.erase('mock', '0.1', '0.0.2')

    %x(pkill -USR1 -f /usr/sbin/mcollectived)
  end

  cart_repo.clear
  cart_repo.load
end
