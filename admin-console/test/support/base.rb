class ActiveSupport::TestCase

  def self.fixture_path
    File.dirname(__FILE__) + "/../fixtures/"
  end

  def with_app
    random = rand(1000000000)
    login = "user#{random}"
    password = 'password'
    user = CloudUser.new(login: login)
    user.private_ssl_certificates = true
    user.save
    Lock.create_lock(user.id)
    register_user(login, password)

    stubber
    namespace = "ns#{random}"
    domain = Domain.new(namespace: namespace, owner:user)
    domain.save
    app_name = "app#{random}"
    app = Application.create_app(app_name, cartridge_instances_for(:php), domain)
    app.save

    app
  end

end
