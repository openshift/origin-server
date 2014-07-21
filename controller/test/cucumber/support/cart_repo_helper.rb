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
    manifest_path        = File.join(%W(/ usr libexec openshift cartridges #{cart} metadata manifest.yml))
    manifest_backup_path = manifest_path + '~'

    if cart_repo.exist?('redhat', cart, '0.1', '0.0.2')
      $logger.info("Erasing test-generated version #{cart}-0.1 (0.0.2)")
      cart_repo.erase('redhat', cart, '0.1', '0.0.2', true)

      if cart_repo.exist?('redhat', cart, '0.2', '0.0.2')
        $logger.info("Erasing test-generated version #{cart}-0.2 (0.0.2)")
        cart_repo.erase('redhat', cart, '0.2', '0.0.2', true)
      end

      if File.exist?(manifest_backup_path)
        $logger.info("Restoring #{cart} #{manifest_path}")
        FileUtils.copy(manifest_backup_path, manifest_path)
      end

      restart_mcollectived = true
    end
  end

  if restart_mcollectived
    if File.exists?("/etc/fedora-release")
      %x(service mcollective restart)
    else
      %x(service ruby193-mcollective restart)
    end
  end

  sleep 5

  cart_repo.clear
  cart_repo.load
end
