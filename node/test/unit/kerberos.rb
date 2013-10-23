# Test the OpenShift::ApplicationContainer::Kerberos module
#
#
require 'test/unit'
require 'mocha/setup'

require 'parseconfig'
require 'tempfile'

require 'openshift-origin-node/model/application_container_ext/kerberos'

include OpenShift::Runtime::ApplicationContainerExt::Kerberos

module OpenShift
  module Runtime
    module Utils

      # used to set the SELinux context of the k5login file
      # stub for testing
      def self.oo_spawn(command)
        # noop
        #puts "called oo_spawn with command #{command}"
      end
    end
  end
end

#
# The K5login class depends on the ApplicationContainer instance passed in
# Specifically it uses the uuid and container_dir attributes
#
#class OpenShift::Runtime::ApplicationContainer
class Container

  attr_reader :uuid, :container_dir

  def initialize(uuid, container_dir)
    @uuid = uuid
    @container_dir = container_dir
  end

end

class TestK5login < Test::Unit::TestCase

  # Test object initialization with default values
  #
  def setup
    @initfile = File.expand_path "test/unit/data/k5login_test_modify_read"

    @username = 'aabbccddeeff00112233445566778899'
    @homedir = '/home/' + @username
    @container = Container.new(@username, @homedir)

  end

  # Verify that object initialization produces the correct values for defaults
  #  
  def test_initialize_default

    k = K5login.new(@container)

    # All explicit 
    assert_same(@container, k.container, "K5login container not set correctly")
    assert_equal(@username, k.username, "K5login username not set correctly")
    assert_equal('/etc/krb5.conf', k.config_file, 
                 "K5login configuration file not defaulted correctly")
    assert_equal(@homedir + "/.k5login", k.filename,
                 "K5login principal file name not defaulted correctly")

  end

  # Test object initialization with explicit values
  #
  def test_initialize_explicit
    
    config_file = File.expand_path "test/unit/data/krb5.conf"
    filename = File.expand_path "test/unit/tmp/test_k5login"

    k = K5login.new(@container, config_file, filename)
    k.owner = nil
    k.group = nil
    k.mode = nil

    assert_same(@container, k.container, "K5login container not set correctly")
    assert_equal(@username, k.username, "K5login username not set correctly")
    assert_equal(config_file, k.config_file, 
                 "K5login configuration file not set correctly")
    assert_equal(filename, k.filename,
                 "K5login principal file name not set correctly")

  end

  # Test object initialization with a config file
  #
  # Three cases:
  #   Config file does not exist: return to defaults
  #   Config file exists, k5login_directory not set: return to defaults
  #   Config file exists, k5login_directory set: append username to path
  # 
  def test_init_config_file

    nonexistent = "/no/such/file"
    exists_unset = "/dev/null"
    exists_set = File.expand_path "test/unit/data/krb5.conf-k5login_directory"

    k_no_conf = K5login.new(@container, nonexistent)
    assert_equal(@homedir + "/.k5login", k_no_conf.filename,
      "K5login principal file name not set correctly: krb5.conf does not exist")

    k_unset = K5login.new(@container, exists_unset)
    assert_equal(@homedir + "/.k5login", k_unset.filename,
      "K5login principal file name not set correctly: krb5.conf exists")

    k_set = K5login.new(@container, exists_set)
    assert_equal("/random/location/" + @username, k_set.filename,
      "K5login principal file name not set correctly: krb5.conf override")
    
  end
  
  # Verify that the k5login_file method produces correct results
  #
  # This is almost, but not quite identical to the initialization test above
  #
  def test_k5login_file

    nonexistent = "/no/such/file"
    exists_unset = "/dev/null"
    exists_set = File.expand_path "test/unit/data/krb5.conf-k5login_directory"

    k_no_conf = K5login.new(@container, nonexistent)
    assert_equal(@homedir + "/.k5login", k_no_conf.k5login_file,
      "K5login principal file name not produced: krb5.conf does not exist")

    k_unset = K5login.new(@container, exists_unset)
    assert_equal(@homedir + "/.k5login", k_unset.k5login_file,
      "K5login principal file name not produced: krb5.conf exists")

    k_set = K5login.new(@container, exists_set)
    assert_equal("/random/location/" + @username, k_set.k5login_file,
      "K5login principal file name not produced: krb5.conf override")
    
  end

  #
  #
  #
  def test_add_principal_first

    lockfile = Tempfile.new ["openshift-origin-node-test-kerberos-", "-lock"]

    new_file = Tempfile.new ["openshift-origin-node-test-kerberos-", "-k5login"]
    new_filename = new_file.path
    # Tempfile creates the file but modify must do it
    File.delete new_filename

    # K5login.modify calls Etc.getpwname to set ownership. usually root
    Etc.stubs(:getpwnam).returns(Struct::Passwd.new)

    begin
      assert((not File.exists?(new_filename)), "file exists before first access: #{new_filename}")

      k_first = K5login.new(@container, nil, new_filename)
      k_first.lockfile = lockfile.path

      k_first.add_principal "testuser1@EXAMPLE.COM", "id1"

      assert(File.exists?(new_filename), "add_principal did not create file #{new_filename}")

      lines = open(new_filename) {|f| f.readlines }

      assert_equal("# id: id1\n", lines[0], "invalid id line")
      assert_equal("testuser1@EXAMPLE.COM\n", lines[1], "invalid principal line")
    ensure
      lockfile.delete
      new_file.delete
    end
  end


  def test_add_principal_new_id
    
    Etc.stubs(:getpwnam).with(@username).returns(Struct::Passwd.new)
    Etc.stubs(:getpwnam).with('root').returns(Struct::Passwd.new)

    lockfile = Tempfile.new(["node-test-kerberos-", "-new_id-lock"])
    new_file = Tempfile.new(['node-test-kerberos-', '-new_id-k5login'])
    new_filename = new_file.path

    new_principal = 'newprincipal1@EXAMPLE.COM'
    new_id = 'newid1'

    begin
      FileUtils.copy_file(@initfile, new_filename)

      k_add = K5login.new(@container, nil, new_filename)
      k_add.lockfile = lockfile.path

      k_add.add_principal new_principal, new_id

      assert(k_add.principals.member? new_principal)
      assert_equal(1, k_add.principals[new_principal].length,
                   "failed to add new principal #{new_principal}\n" +
                   "-- ids = #{k_add.principals[new_principal].to_a.to_s}")

      k_add.add_principal new_principal, 'newid2'

      assert(k_add.principals.member? new_principal)
      assert_equal(2, k_add.principals[new_principal].length,
                   "failed to add new id to #{new_principal}\n" +
                   "-- new id: newid2\n" +
                   "-- ids = #{k_add.principals[new_principal].to_a.to_s}")
      assert_equal(2, k_add.principals[new_principal].length,
                   "failed to find two ids\n" +
                   "-- #{k_add.principals[new_principal].to_a.to_s}")
     
      k_check = K5login.new(@container, nil, new_filename)
      k_check.lockfile = lockfile.path

      # verify that new object reads the same as the old one
      assert(k_check.principals.member? new_principal)
      assert_equal(2, k_check.principals[new_principal].length,
                   "failed to find two ids\n" +
                   "-- #{k_add.principals[new_principal].to_a.to_s}")
    ensure
      new_file.delete
      lockfile.delete
    end
  end

  def test_remove_principal_old_id
    
    lockfile = Tempfile.new(["node-test-kerberos-", "-rm_id-lock"])
    old_file = Tempfile.new(['node-test-kerberos-', '-rm_id-k5login'])
    old_filename = old_file.path

    #old_principal = 'rmprincipal1@EXAMPLE.COM'
    #old_id = 'rmid1'
    old_principal = 'principal3@EXAMPLE.COM'
    old_id = 'testuser4'

    # K5login.modify calls Etc.getpwname to set ownership. usually root
    Etc.stubs(:getpwnam).returns(Struct::Passwd.new)

    begin
      FileUtils.copy_file(@initfile, old_filename)

      k_rm = K5login.new(@container, nil, old_filename)
      k_rm.lockfile = lockfile.path

      assert(k_rm.principals.member?(old_principal), 
             "unchanged file does not contain principal #{old_principal}")

      k_rm.remove_principal old_principal, old_id

      assert(k_rm.principals.member? old_principal)
      assert_equal(2, k_rm.principals[old_principal].length,
                   "failed to remove old principal id #{old_principal} #{old_id}\n" +
                   "-- ids = #{k_rm.principals[old_principal].to_a.to_s}")

      assert_equal(Set.new(['testuser2', 'testuser6']),
                   k_rm.principals[old_principal], 
                   "incorrect remaining ids")
      k_rm.remove_principal old_principal, 'testuser2'
      k_rm.remove_principal old_principal, 'testuser6'

      assert(not(k_rm.principals.member?old_principal))
     
      k_check = K5login.new(@container, nil, old_filename)
      k_check.lockfile = lockfile.path

      # verify that new object reads the same as the old one
      assert(not(k_check.principals.member?(old_principal)))

    ensure
      old_file.delete
      lockfile.delete
    end
  end

  # Add a principal with no ID
  # Then add the same principal with an ID
  # 
  def test_add_principal_nil_id
    lockfile = Tempfile.new(["node-test-kerberos-", "-new_id-lock"])
    new_file = Tempfile.new(['node-test-kerberos-', '-new_id-k5login'])
    new_filename = new_file.path

    new_principal = 'newprincipal1@EXAMPLE.COM'
    new_id = 'newid1'

    # K5login.modify calls Etc.getpwname to set ownership. usually root
    Etc.stubs(:getpwnam).returns(Struct::Passwd.new)

    begin
      # 'touch' the test file
      open(new_filename, 'w') { |f| f.write '# id: dummy\ndummy@EXAMPLE.COM\n' }

      k_add = K5login.new(@container, nil, new_filename)
      k_add.lockfile = lockfile.path

      # Add a principal with nil id
      k_add.add_principal new_principal, nil

      assert(k_add.principals.member? new_principal)
      assert_equal(1, k_add.principals[new_principal].length,
                   "failed to add new principal #{new_principal} with nil id\n" +
                   "-- ids = #{k_add.principals[new_principal].to_a.to_s}")

      k_add.add_principal new_principal, 'newid2'

      assert(k_add.principals.member? new_principal)
      assert_equal(2, k_add.principals[new_principal].length,
                   "failed to add new id to #{new_principal}\n" +
                   "-- new id: newid2\n" +
                   "-- ids = #{k_add.principals[new_principal].to_a.to_s}")
     
      k_check = K5login.new(@container, nil, new_filename)
      k_check.lockfile = lockfile.path

      # verify that new object reads the same as the old one
      assert(k_check.principals.member? new_principal)
      assert_equal(2, k_check.principals[new_principal].length,
                   "failed to find one ids\n" +
                   "-- #{k_add.principals[new_principal].to_a.to_s}")
    ensure
      new_file.delete
      lockfile.delete
    end

  end

  def test_remove_principal_nil_id

    # write a file with a single principal/id

    # remove the principal/id

    # the k5login file should have been removed completely

    lockfile = Tempfile.new(["node-test-kerberos-", "-rm_last-lock"])
    old_file = Tempfile.new(['node-test-kerberos-', '-rm_last-k5login'])

    # K5login.modify calls Etc.getpwname to set ownership. usually root
    Etc.stubs(:getpwnam).returns(Struct::Passwd.new)

    nilid1 = "nilid1@EXAMPLE.COM"
    nilid2 = "nilid2@EXAMPLE.COM"

    begin
      # create two entries to be removed
      # One has no id strings at all
      # The other has a single ID entry with no content
      # Both should be removed
      open old_file.path, "w" do |f| 
        f.write "#{nilid1}\n\n# id: \n#{nilid2}" 
      end

      k_rm = K5login.new(@container, nil, old_file.path)
      k_rm.lockfile = lockfile.path

      k_rm.remove_principal nilid1

      assert(not(k_rm.principals.member?(nilid1)), 
             "unchanged file does not contain principal #{nilid1}")

      k_rm.remove_principal nilid2

      assert(not(File.exists?(old_file.path)))

    ensure
      old_file.delete
      lockfile.delete
    end
  end

  # principals which have been placed originally with no id must be
  # preserved when the last id is removed.
  # This means the knowledge that the principal has a "null id" instance
  # must be preserved even when other ids are added and removed.
  #
  # When a principal has only a null id, then no id: lines will be present
  # If a principal has both a null id and OpenShift managed ids, the null id
  # will be represented as an empty string '' in the id set.
  #
  # work with the "notowned@EXAMPLE.COM" principal in the sample_text
  #
  def test_preserve_null_id
    
    lockfile = Tempfile.new(["node-test-kerberos-", "-nullid-lock"])
    k5login_file = Tempfile.new(['node-test-kerberos-', '-nullid-k5login'])

    test_principal = 'notowned@EXAMPLE.COM'

    # K5login.modify calls Etc.getpwname to set ownership. usually root
    Etc.stubs(:getpwnam).returns(Struct::Passwd.new)

    begin
      # create the file to be removed
      open k5login_file.path, "w" do |f| 
        f.write @@k5login_sample_text
      end

      # create the k5login management object
      # check that principal exists and indicates null id
      k_preserve = K5login.new(@container, nil, k5login_file.path)
      k_preserve.lockfile = lockfile.path

      assert(k_preserve.principals.member? test_principal)

      principal_ids = k_preserve.principals[test_principal]

      # add an id
      k_preserve.add_principal test_principal, 'id1'
      
      # check that principal retains null id
      assert(k_preserve.principals[test_principal].member?(nil),
             "nil id disappeared when new id added to principal"
             )

      # remove the new id
      k_preserve.remove_principal test_principal, 'id1'

      # check that principal still exists and indicates null id
      assert(k_preserve.principals.member?(test_principal),
             "principal removed when nil id remained"
             )
      assert(k_preserve.principals[test_principal].member?(nil),
             "nil id disappeared when new id removed from principal"
             )

    ensure
      k5login_file.close
      k5login_file.delete
      lockfile.close
      lockfile.delete
    end

  end

  def test_replace_principals


    lockfile = Tempfile.new(["node-test-kerberos-", "-replace-lock"])
    k5login_file = Tempfile.new(['node-test-kerberos-', '-replace-k5login'])
    k5login_filename = k5login_file.path

    # K5login.modify calls Etc.getpwname to set ownership. usually root
    Etc.stubs(:getpwnam).returns(Struct::Passwd.new)

    begin
      # create the file to be removed
      open k5login_filename, "w" do |f| 
        f.write @@k5login_sample_text
      end

      k_replace = K5login.new(@container, nil, k5login_filename)
      k_replace.lockfile = lockfile.path


      k_replace.replace_principals @@k5login_replace_principals_input

      assert_equal(Set.new(['replace1@EXAMPLE.COM',
                            'replace2@EXAMPLE.COM',
                            'replace3@EXAMPLE.COM']), 
                   Set.new(k_replace.principals.keys),
                   'key set does not match')

      assert_equal(Set.new(['replaceid1', 'replaceid2', 
                            'replaceid3', 'replaceid4']),
                   k_replace.principals['replace1@EXAMPLE.COM'],
                   'id set for key replace1@EXAMPLE.COM does not match')

      assert_equal(Set.new(['replaceid2']),
                   k_replace.principals['replace2@EXAMPLE.COM'],
                   'id set for key replace2@EXAMPLE.COM does not match')

      assert_equal(Set.new([nil]),
                   k_replace.principals['replace3@EXAMPLE.COM'],
                   'id set for key replace3@EXAMPLE.COM does not match')
    ensure
      k5login_file.delete
      lockfile.delete
    end

  end

  #
  # Verify that the k5login file can be read and produces the expected
  # data structure
  #
  def test_modify_read

    k5_test = K5login.new(@container, nil, @initfile)
    assert_equal(@initfile, k5_test.filename,
      "K5login principal file name incorrectly set")

    # place the lock file someplace sure to exist for now
    lockfile = 
      Tempfile.new(['openshift-origin-node-test', 'kerberos-modify-read'])
    begin

      k5_test.lockfile = lockfile.path
      a = k5_test.principals

      assert_equal(@@k5login_sample_principals, a)

    ensure
      # don't leave trash around
      lockfile.delete
    end
  end

  #
  # Verify that the k5login file can be read and produces the expected
  # data structure
  #
  def test_modify_write

    k5_tempfile = Tempfile.new(['openshift-origin-node-test-', '-k5login'])
    # place the lock file someplace sure to exist for now
    lockfile = 
      Tempfile.new(['openshift-origin-node-test', 'kerberos-modify-read'])

    FileUtils.copy_file(@initfile, k5_tempfile)

    # K5login.modify calls Etc.getpwname to set ownership. usually root
    Etc.stubs(:getpwnam).returns(Struct::Passwd.new)

    begin

      k5_test = K5login.new(@container, nil, k5_tempfile)

      k5_test.lockfile = lockfile.path
      a = k5_test.principals

      assert_equal(@@k5login_sample_principals, a)

    ensure
      # don't leave trash around
      lockfile.delete
      k5_tempfile.delete
    end
  end

  @@k5login_sample_principals = {
    "principal1@EXAMPLE.COM" => Set.new(["testuser1"]), 
    "principal2@EXAMPLE.COM" => 
      Set.new(["testuser4", "testuser5", "testuser6", "testuser7"]),
    "# comments that don't matter" => Set.new,
    "# spaces that don't matter" => Set.new,
    "# the next principal is un-owned" => Set.new,
    "notowned@EXAMPLE.COM" => Set.new([nil]),
    "principal3@EXAMPLE.COM"=> Set.new(["testuser2", "testuser4", "testuser6"])
  }

  # type is irrelevent here: krb5-principal
  @@k5login_replace_principals_input = 
    [
     { 'key' => 'replace1@EXAMPLE.COM', 'comment' => 'replaceid1' },
     { 'key' => 'replace1@EXAMPLE.COM', 'comment' => 'replaceid2' },
     { 'key' => 'replace1@EXAMPLE.COM', 'comment' => 'replaceid3' },
     { 'key' => 'replace2@EXAMPLE.COM', 'comment' => 'replaceid2' },
     { 'key' => 'replace1@EXAMPLE.COM', 'comment' => 'replaceid4' },
     { 'key' => 'replace3@EXAMPLE.COM', 'comment' => nil },
    ]
  #
  # This is the contents of a sample k5login file for testing
  #
  @@k5login_sample_text = <<EOF
# id: testuser1
principal1@EXAMPLE.COM

# id: testuser4
#       id:    testuser5    
# id: testuser6   
principal2@EXAMPLE.COM

# comments that don't matter

# spaces that don't matter

# the next principal is un-owned

notowned@EXAMPLE.COM

# id: testuser2
# id: testuser4
# id: testuser6
principal3@EXAMPLE.COM
EOF

end


