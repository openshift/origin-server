#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++
require_relative '../test_helper'
require 'pathname'

# Deploy cannot be testing in this manner. SELinux requires a valid UID or the tests fail.
# See cucumber test application_repository.feature
class ApplicationRepositoryFuncTest < OpenShift::NodeTestCase
  GEAR_BASE_DIR = '/var/lib/openshift'

  def before_setup
    super
    @uid = 5997

    @config = mock('OpenShift::Config')
    @config.stubs(:get).returns(nil)
    @config.stubs(:get).with("GEAR_BASE_DIR").returns(GEAR_BASE_DIR)
    @config.stubs(:get).with("GEAR_GECOS").returns('Functional Test')
    @config.stubs(:get).with("CREATE_APP_SYMLINKS").returns('0')
    @config.stubs(:get).with("GEAR_SKEL_DIR").returns(nil)
    @config.stubs(:get).with("GEAR_SHELL").returns(nil)
    @config.stubs(:get).with("CLOUD_DOMAIN").returns('example.com')
    @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns('/etc/httpd/conf.d/openshift')
    @config.stubs(:get).with("PORT_BEGIN").returns(nil)
    @config.stubs(:get).with("PORT_END").returns(nil)
    @config.stubs(:get).with("PORTS_PER_USER").returns(5)
    @config.stubs(:get).with("UID_BEGIN").returns(@uid)
    @config.stubs(:get).with("BROKER_HOST").returns('localhost')
    @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns('.')
    OpenShift::Config.stubs(:new).returns(@config)

    @uuid = `uuidgen -r |sed -e s/-//g`.chomp

    begin
      %x(userdel -f #{Etc.getpwuid(@uid).name})
    rescue ArgumentError
    end

    @user = OpenShift::UnixUser.new(@uuid, @uuid,
                                    @uid,
                                    'AppRepoFuncTest',
                                    'AppRepoFuncTest',
                                    'functional-test')
    @user.create

    OpenShift::CartridgeRepository.instance.clear
    OpenShift::CartridgeRepository.instance.load

    @state = mock('OpenShift::Utils::ApplicationState')
    @state.stubs(:value=).with('started').returns('started')

    @hourglass = mock()
    @hourglass.stubs(:remaining).returns(3600)

    @model               = OpenShift::V2CartridgeModel.new(@config, @user, @state, @hourglass)
    @cartridge_name      = 'mock-0.1'
    @cartridge_directory = 'mock'
    @cartridge_home      = File.join(@user.homedir, @cartridge_directory)
    @model.configure(@cartridge_name)
    teardown
  end

  def after_teardown
    @user.destroy
  end

  def teardown
    FileUtils.rm_rf(File.join(@user.homedir, @cartridge_directory, 'template'))
    FileUtils.rm_rf(File.join(@user.homedir, @cartridge_directory, 'template.git'))
    FileUtils.rm_rf(File.join(@user.homedir, @cartridge_directory, 'usr', 'template'))
    FileUtils.rm_rf(File.join(@user.homedir, @cartridge_directory, 'usr', 'template.git'))
  end

  def assert_bare_repository(repo)
    assert_path_exist repo.path
    assert_path_exist File.join(repo.path, 'description')
    assert_path_exist File.join(@user.homedir, '.gitconfig')
    assert_path_exist File.join(repo.path, 'hooks', 'pre-receive')
    assert_path_exist File.join(repo.path, 'hooks', 'post-receive')

    files = Dir[repo.path + '/objects/**/*']
    assert files.count > 0, 'Error: Git repository missing objects'
    files.each { |f|
      stat = File.stat(f)
      assert_equal @user.uid, stat.uid, 'Error: Git object wrong ownership'
    }

    stat = File.stat(File.join(repo.path, 'hooks'))
    assert_equal 0, stat.uid, 'Error: Git hook directory not owned by root'

    stat = File.stat(File.join(repo.path, 'hooks', 'post-receive'))
    assert_equal 0, stat.uid, 'Error: Git hook post-receive not owned by root'
  end

  def test_new
    repo = OpenShift::ApplicationRepository.new(@user)
    refute_nil repo
  end

  def test_no_template
    template = File.join(@user.homedir, @cartridge_directory, 'template')
    FileUtils.rm_rf template
    repo = OpenShift::ApplicationRepository.new(@user)
    refute_path_exist template
    repo.archive
  end

  def test_bare_repository_usr
    create_template(File.join(@cartridge_home, 'usr', 'template', 'perl'))
    create_bare(File.join(@cartridge_home, 'usr', 'template'))

    cartridge_template_git = File.join(@cartridge_home, 'usr', 'template.git')
    assert_path_exist cartridge_template_git
    refute_path_exist File.join(@cartridge_home, 'usr', 'template')

    expected_path = File.join(@user.homedir, 'git', @user.app_name + '.git')

    repo = OpenShift::ApplicationRepository.new(@user)
    repo.destroy

    repo.populate_from_cartridge(@cartridge_directory)

    assert_equal expected_path, repo.path
    assert_bare_repository(repo)
    assert repo.exist?, "Application Repository (#{repo.path}) not found"
    assert repo.exists?, "Application Repository (#{repo.path}) not found"
  end

  def test_bare_repository
    create_template(File.join(@cartridge_home, 'template', 'perl'))
    create_bare(File.join(@cartridge_home, 'template'))

    cartridge_template_git = File.join(@cartridge_home, 'template.git')
    assert_path_exist cartridge_template_git
    refute_path_exist File.join(@cartridge_home, 'template')

    expected_path = File.join(@user.homedir, 'git', @user.app_name + '.git')

    repo = OpenShift::ApplicationRepository.new(@user)
    repo.destroy

    begin
      repo.populate_from_cartridge(@cartridge_directory)
    rescue OpenShift::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end

    assert_equal expected_path, repo.path
    assert_bare_repository(repo)
    assert repo.exist?, "Application Repository (#{repo.path}) not found"
    assert repo.exists?, "Application Repository (#{repo.path}) not found"
  end

  def test_from_url
    create_template(File.join(@cartridge_home, 'template', 'perl'))
    create_bare(File.join(@cartridge_home, 'template'))

    cartridge_template_git = File.join(@cartridge_home, 'template.git')
    assert_path_exist cartridge_template_git
    refute_path_exist File.join(@cartridge_home, 'template')
    cartridge_template_url = "file://#{cartridge_template_git}"

    expected_path = File.join(@user.homedir, 'git', @user.app_name + '.git')

    repo = OpenShift::ApplicationRepository.new(@user)
    repo.destroy

    begin
      repo.populate_from_url(@cartridge_name, cartridge_template_url)
    rescue OpenShift::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end

    assert_equal expected_path, repo.path
    assert_bare_repository(repo)
  end

  def test_from_ssh_url
    e = assert_raise(OpenShift::Utils::ShellExecutionException) do
      repo = OpenShift::ApplicationRepository.new(@user)
      repo.destroy
      repo.populate_from_url(@cartridge_name, 'git@github.com:jwhonce/origin-server.git')
    end

    assert_equal 130, e.rc
    assert e.message.start_with?('CLIENT_ERROR:')
  end

  def test_source_usr
    refute_path_exist File.join(@cartridge_home, 'template.git')

    create_template(File.join(@cartridge_home, 'usr', 'template', 'perl'))
    expected_path = File.join(@user.homedir, 'git', @user.app_name + '.git')

    repo = OpenShift::ApplicationRepository.new(@user)
    repo.destroy
    refute_path_exist(expected_path)

    begin
      repo.populate_from_cartridge(@cartridge_directory)

      assert_equal expected_path, repo.path
      assert_bare_repository(repo)

      runtime_repo = "#{@user.homedir}/app-root/runtime/repo"
      FileUtils.mkpath(runtime_repo)
      repo.archive
      assert_path_exist File.join(runtime_repo, 'perl', 'health_check.pl')
    rescue OpenShift::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end
  end

  def test_source
    create_template(File.join(@cartridge_home, 'template', 'perl'))
    expected_path = File.join(@user.homedir, 'git', @user.app_name + '.git')
    refute_path_exist File.join(@cartridge_home, 'template.git')

    repo = OpenShift::ApplicationRepository.new(@user)
    repo.destroy
    refute_path_exist(expected_path)

    begin
      repo.populate_from_cartridge(@cartridge_directory)

      assert_equal expected_path, repo.path
      assert_bare_repository(repo)

      runtime_repo = "#{@user.homedir}/app-root/runtime/repo"
      FileUtils.mkpath(runtime_repo)
      repo.archive
      assert_path_exist File.join(runtime_repo, 'perl', 'health_check.pl')
    rescue OpenShift::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end
  end

  def test_bare_submodule
    create_template(File.join(@cartridge_home, 'template', 'perl'))
    create_bare_submodule
    expected_path = File.join(@user.homedir, 'git', @user.app_name + '.git')

    repo = OpenShift::ApplicationRepository.new(@user)
    repo.destroy
    refute_path_exist(expected_path)

    begin
      repo.populate_from_cartridge(@cartridge_directory)

      assert_equal expected_path, repo.path
      assert_bare_repository(repo)

      runtime_repo = "#{@user.homedir}/app-root/runtime/repo"
      FileUtils.mkpath(runtime_repo)
      repo.archive
      assert_path_exist File.join(runtime_repo, 'perl', 'health_check.pl')
      assert_path_exist File.join(runtime_repo, 'module001', 'README.md')
    rescue OpenShift::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end
  end

  def create_template(path)
    # Cartridge Author tasks...
    #perl = File.join(@cartridge_home, 'template', 'perl')
    FileUtils.mkpath(path)

    File.open(File.join(path, 'health_check.pl'), 'w', 0664) { |f|
      f.write(%q{\
#!/usr/bin/perl
print "Content-type: text/plain\r\n\r\n";
print "1";
})
    }

    File.open(File.join(path, 'index.pl'), 'w', 0664) { |f|
      f.write(%q{\
#!/usr/bin/perl
print "Content-type: text/html\r\n\r\n";
print <<EOF
  <html>
    <head>
      <title>Welcome to OpenShift</title>
    </head>
    <body>
      <p>Welcome to OpenShift
    </body>
  </html>
EOF
})
      FileUtils.chown_R(@user.uid, @user.uid, path)
    }
  end

  def create_bare(template)
    Dir.chdir(@cartridge_home) do
      output = %x{set -xe;
pushd #{template};
git init;
git config user.email "mocker@example.com";
git config user.name "Mock Template builder";
git add -f .;
git </dev/null commit -a -m "Creating mocking template" 2>&1;
cd ..;
git </dev/null clone --bare --no-hardlinks template template.git 2>&1;
chown -R #{@user.uid}:#{@user.uid} template template.git;
popd;
}

      #puts "\ncreate_bare: #{output}"

      FileUtils.rm_r(template)
    end
  end

  def create_bare_submodule
    template  = File.join(@cartridge_home, 'template')
    submodule = File.join(@cartridge_home, 'module001')

    Dir.chdir(@cartridge_home) do
      output = %x{set -xe;
mkdir module001;
pushd module001;
git init;
git config user.email "module@example.com";
git config user.name "Mock Module builder";
touch README.md;
git add -f .;
git </dev/null commit -a -m "Creating module" 2>&1;
popd

pushd #{template}
git init;
git config user.email "mocker@example.com";
git config user.name "Mock Template builder";
git add -f .;
git </dev/null commit -a -m "Creating mocking template" 2>&1;
git submodule add #{submodule} module001
git submodule update --init
git </dev/null commit -m 'Added submodule module001'
popd;
git </dev/null clone --bare --no-hardlinks template template.git 2>&1;
chown -R #{@user.uid}:#{@user.uid} template template.git
}
      FileUtils.chown_R(@user.uid, @user.uid, template)
      #puts "\ncreate_bare_submodule: #{output}"

      FileUtils.rm_r(template)
    end
  end
end
