After('@domain_member_test_1') do
  clean_domains
end

After('@domain_member_test_2') do
  clean_domains
end

def clean_domains
  if @unique_namespace_apps_hash.nil? || @unique_namespace_apps_hash.empty?
    $logger.info("No unique domains found, not deleting domains.")
    return
  end
  @unique_namespace_apps_hash.each do |namespace, app|
    rhc_delete_domain(app)
  end
  @unique_namespace_apps_hash = {}
end
