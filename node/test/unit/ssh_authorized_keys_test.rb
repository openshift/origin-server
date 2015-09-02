#!/usr/bin/env oo-ruby
#
# Test the SecureShell::AuthorizedKeysFile model
#
#
require_relative '../test_helper'
require 'tempfile'
require 'fileutils'

class TestAuthorizedKeysFile < OpenShift::NodeTestCase
  def setup
    @config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")

    # Set up the container
    @gear_uuid = '5504'
    @user_uid  = '5504'
    @app_name  = 'AuthoizedKeysFileTestCase'
    @namespace = 'jwh201204301647'

    Etc.stubs(:getpwnam).returns(
        OpenStruct.new(
            uid:   @user_uid.to_i,
            gid:   @user_uid.to_i,
            gecos: "OpenShift guest",
            dir:   "/var/lib/openshift/#{@gear_uuid}"
        )
    )

    @initfile = File.expand_path "test/unit/data/ssh_authorized_keys_init"
    @homedir = "/var/lib/openshift/#{@gear_uuid}/"
    @container = OpenShift::Runtime::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid,
                                                              @app_name, @gear_uuid, @namespace, nil, nil, nil)
  end

  # Verify that new AuthorizedKeysFile objects are initialized correctly
  #
  def test_initialize_default
    keyfile = AuthorizedKeysFile.new(@container)
    assert_same(@container, keyfile.container, 
                'AuthorizedKeysFile container not set correctly')
    assert_equal(@gear_uuid, keyfile.username, 
                 'AuthorizedKeysFile username not set correctly')
    assert_equal(@homedir + "/.ssh/authorized_keys", keyfile.filename, 
                 'AuthorizedKeysFile filename not set correctly')
    assert_equal('/bin/bash', @container.container_plugin.gear_shell, 
                 'AuthorizedKeysFile container shell not set correctly')
  end

  def test_initialize_explicit
    filename = File.expand_path "test/unit/tmp/test_authorized_keys"

    keyfile = AuthorizedKeysFile.new(@container, filename)

    assert_same(@container, keyfile.container, 
                'AuthorizedKeysFile container not set correctly')
    assert_equal(@gear_uuid, keyfile.username, 
                 'AuthorizedKeysFile username not set correctly')
    assert_equal(filename, keyfile.filename, 
                 'AuthorizedKeysFile filename not set correctly')
    assert_equal('/bin/bash', @container.container_plugin.gear_shell, 
                 'AuthorizedKeysFile container shell not set correctly')
    
  end

  def test_authorized_keys_read
    # define the temporary file locations
    lockfile = Tempfile.new ['openshift-origin-node-test-authkey-', '-lock']
    keyfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-',
                            '-keyfile']

    keyfile_name = keyfile.path

    begin 
      FileUtils.copy @initfile, keyfile_name

      # initialize the authorized keys file

      # create the AuthorizedKeysFile object
      auth_keys = AuthorizedKeysFile.new(@container, keyfile_name)
      auth_keys.lockfile = lockfile

      # pick three relatively at random
      assert_equal("command=\"/bin/false\",no-X11-fowarding ssh-rsa aabbccddeeffgg0011223344556677889900 OPENSHIFT-testuser1-keyid1",
                   auth_keys.authorized_keys['OPENSHIFT-testuser1-keyid1'])

      assert_equal('command="/bin/false",no-X11-fowarding ssh-rsa aabbccddeeffgg0011223344556677889900 OPENSHIFT-testuser1-keyid2',
                   auth_keys.authorized_keys['OPENSHIFT-testuser1-keyid2'])

      assert_equal('command="/bin/false",no-X11-fowarding ssh-rsa 0011223344556677889900aabbccddeeffgg OPENSHIFT-testuser1-keyid5',
                   auth_keys.authorized_keys['OPENSHIFT-testuser1-keyid5'])

    ensure
      lockfile.delete
      keyfile.delete
    end
  end

  def test_add_key_first

    # define where the lock and authorized keys file will go
    # define the temporary file locations
    lockfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-firstkey',
                             '-lock']
    keyfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-firstkey',
                            '-keyfile']

    new_key = {
      'key' => "testkey",
      'type' => 'ssh-rsa',
      'id' => 'id1'
    }
    
    key_entry_sample = 
      'command="/bin/bash",no-X11-forwarding ssh-rsa testkey OPENSHIFT-5504-id1'

    # Ensure the file does not exist before adding the first entry
    File.delete keyfile.path

    begin
      auth_keys = AuthorizedKeysFile.new(@container, keyfile.path)
      auth_keys.lockfile = lockfile

      # a sample key for input

      auth_keys.add_key(new_key['key'], new_key['type'], new_key['id'])

      assert(File.exists?(keyfile.path), 
             "key file does not exist after add: #{keyfile.path}")

      assert_equal(73, File.size(keyfile.path))

      File.open(keyfile.path) {|f|
        lines = f.readlines.map {|l| l.strip }
        assert_equal(1, lines.length,
                     "incorrect number of entries after one add")
        assert_equal(72, lines[0].length,
                     "incorrect number of characters in key entry 0")
        assert_equal(key_entry_sample, lines[0],
                     "key entry does not match")
      }
    ensure
      keyfile.delete
      lockfile.delete
    end
  end

  def test_add_key_nil_id
    # define where the lock and authorized keys file will go
    # define the temporary file locations
    lockfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-nilid',
                             '-lock']
    keyfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-nilid',
                            '-keyfile']

    new_key = {
      'key' => "testkey",
      'type' => 'ssh-rsa',
      'id' => nil
    }
    
    key_entry_sample = 
      'command="/bin/bash",no-X11-forwarding ssh-rsa testkey OPENSHIFT-5504-'

    # Ensure the file does not exist before adding the first entry
    File.delete keyfile.path

    begin
      auth_keys = AuthorizedKeysFile.new(@container, keyfile.path)
      auth_keys.lockfile = lockfile

      # a sample key for input

      auth_keys.add_key(new_key['key'], new_key['type'], new_key['id'])

      assert(File.exists?(keyfile.path), 
             "key file does not exist after add: #{keyfile.path}")

      File.open(keyfile.path) {|f|
        lines = f.readlines.map {|l| l.strip }
        assert_equal(1, lines.length,
                     "incorrect number of entries after one add")
        assert_equal(key_entry_sample.length, lines[0].length,
                     "incorrect number of characters in key entry0")
        assert_equal(key_entry_sample, lines[0],
                     "key entry does not match")
      }
    ensure
      keyfile.delete
      lockfile.delete
    end
  end


  def test_add_key_new_key
    # define where the lock and authorized keys file will go
    # define the temporary file locations
    lockfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-newkey-',
                             '-lock']
    keyfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-newkey-',
                            '-keyfile']

    new_key = [
                {
                  'key' => "testkey1",
                  'type' => 'ssh-rsa',
                  'id' => 'id1'
                },
                {
                  'key' => "testkey2",
                  'type' => 'ssh-rsa',
                  'id' => 'id2'
                }
               ]
    
    key_entry_sample = 
      [
       'command="/bin/bash",no-X11-forwarding ssh-rsa testkey1 OPENSHIFT-5504-id1',
       'command="/bin/bash",no-X11-forwarding ssh-rsa testkey2 OPENSHIFT-5504-id2'
      ]
       
    # Ensure the file does not exist before adding the first entry
    File.delete keyfile.path

    begin
      auth_keys = AuthorizedKeysFile.new(@container, keyfile.path)
      auth_keys.lockfile = lockfile

      # a sample key for input

      auth_keys.add_key(new_key[0]['key'], new_key[0]['type'], new_key[0]['id'])

      assert(File.exists?(keyfile.path), 
             "key file does not exist after add: #{keyfile.path}")
      assert(File.writable?(keyfile.path),
             "key file not writable after create: #{keyfile.path}")

      auth_keys.add_key(new_key[1]['key'], new_key[1]['type'], new_key[1]['id'])

      assert_equal(148, File.size(keyfile.path))

      File.open(keyfile.path) {|f|
        lines = f.readlines.map {|l| l.strip }
        assert_equal(2, lines.length,
                     "incorrect number of entries after one add")
        assert_equal(73, lines[0].length,
                     "incorrect number of characters in key entry 0")
        assert_equal(key_entry_sample[0], lines[0],
                     "key entry does not match")
      }
    ensure
      keyfile.delete
      lockfile.delete
    end
  end

  def test_add_key_add_id

    # define where the lock and authorized keys file will go
    # define the temporary file locations
    lockfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-newkey-',
                             '-lock']
    keyfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-newkey-',
                            '-keyfile']

    new_key = [
                {
                  'key' => "testkey1",
                  'type' => 'ssh-rsa',
                  'id' => 'id1'
                },
                {
                  'key' => "testkey1",
                  'type' => 'ssh-rsa',
                  'id' => 'id2'
                }
               ]
    
    key_entry_sample = 
      [
       'command="/bin/bash",no-X11-forwarding ssh-rsa testkey1 OPENSHIFT-5504-id1',
       'command="/bin/bash",no-X11-forwarding ssh-rsa testkey1 OPENSHIFT-5504-id2'
      ]
       
    # Ensure the file does not exist before adding the first entry
    File.delete keyfile.path

    begin
      auth_keys = AuthorizedKeysFile.new(@container, keyfile.path)
      auth_keys.lockfile = lockfile

      # a sample key for input

      auth_keys.add_key(new_key[0]['key'], new_key[0]['type'], new_key[0]['id'])

      assert(File.exists?(keyfile.path), 
             "key file does not exist after add: #{keyfile.path}")
      assert(File.writable?(keyfile.path),
             "key file not writable after create: #{keyfile.path}")

      auth_keys.add_key(new_key[1]['key'], new_key[1]['type'], new_key[1]['id'])

      assert_equal(148, File.size(keyfile.path))

      File.open(keyfile.path) {|f|
        lines = f.readlines.map {|l| l.strip }
        assert_equal(2, lines.length,
                     "incorrect number of entries after one add")
        assert_equal(73, lines[0].length,
                     "incorrect number of characters in key entry 0")
        assert_equal(key_entry_sample[0], lines[0],
                     "key entry does not match")
      }
    ensure
      keyfile.delete
      lockfile.delete
    end
  end

  def test_remove_key_id

    # define the temporary file locations
    lockfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-remove',
                             '-lock']
    keyfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-remove',
                            '-keyfile']

    begin 
      # create a one-line file for replacement
      File.open(keyfile.path, 'w') {|f|
        f.write <<EOF
command="/bin/false",no-X11-fowarding ssh-rsa aabbccddeeffgg0011223344556677889900 OPENSHIFT-#{@container.uuid}-keyid1
command="/bin/false",no-X11-fowarding ssh-rsa aabbccddeeffgg0011223344556677889900 OPENSHIFT-#{@container.uuid}-keyid2
command="/bin/false",no-X11-fowarding ssh-rsa keepccddeeffgg0011223344556677889900 OPENSHIFT-#{@container.uuid}-keyid3
command="/bin/false",no-X11-fowarding ssh-rsa keepccddeeffgg0011223344556677889900 OPENSHIFT-#{@container.uuid}-keyid4
EOF
      }
      
      auth_keys = AuthorizedKeysFile.new(@container, keyfile.path)
      auth_keys.lockfile = lockfile

      assert_equal(4, auth_keys.authorized_keys.length,
                   "incorrect number of remaining keys before remove")


      auth_keys.remove_key('aabbccddeeffgg0011223344556677889900',
                           'ssh-rsa',
                           'keyid1')
      assert_equal(3, auth_keys.authorized_keys.length,
                   "incorrect number of remaining keys after one remove")

      auth_keys.remove_key('aabbccddeeffgg0011223344556677889900',
                           'ssh-rsa',
                           'keyid2')

      assert_equal(2, auth_keys.authorized_keys.length,
                   "incorrect number of remaining keys after two removes")
    ensure
      keyfile.close
      keyfile.delete

      lockfile.close
      lockfile.delete
    end
      
  end

  def test_remove_key_nil_id

    # define the temporary file locations
    lockfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-remove-nil',
                             '-lock']
    keyfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-remove-nil',
                            '-keyfile']

    begin 
      # create a one-line file for replacement
      File.open(keyfile.path, 'w') {|f|
        f.write <<EOF
command="/bin/false",no-X11-fowarding ssh-rsa aabbccddeeffgg0011223344556677889900 OPENSHIFT-#{@container.uuid}-keyid1
command="/bin/false",no-X11-fowarding ssh-rsa aabbccddeeffgg0011223344556677889900
command="/bin/false",no-X11-fowarding ssh-rsa keepccddeeffgg0011223344556677889900 OPENSHIFT-#{@container.uuid}-keyid3
command="/bin/false",no-X11-fowarding ssh-rsa keepccddeeffgg0011223344556677889900 OPENSHIFT-#{@container.uuid}-keyid4
EOF
      }
      
      auth_keys = AuthorizedKeysFile.new(@container, keyfile.path)
      auth_keys.lockfile = lockfile

      assert_equal(4, auth_keys.authorized_keys.length,
                   "incorrect number of remaining keys before remove")

      # remove all instances of the key regardless of the id
      auth_keys.remove_key('aabbccddeeffgg0011223344556677889900',
                           'ssh-rsa',
                           nil)
      assert_equal(2, auth_keys.authorized_keys.length,
                   "incorrect number of remaining keys after one remove")

    ensure
      keyfile.close
      keyfile.delete

      lockfile.close
      lockfile.delete
    end
      
  end

  def test_remove_key_last_id

    # define the temporary file locations
    lockfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-remove-last',
                             '-lock']
    keyfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-remove-last',
                            '-keyfile']

    begin 
      # create a one-line file for replacement
      File.open(keyfile.path, 'w') {|f|
        f.write <<EOF
command="/bin/false",no-X11-fowarding ssh-rsa aabbccddeeffgg0011223344556677889900 OPENSHIFT-#{@container.uuid}-keyid1
EOF
      }
      
      auth_keys = AuthorizedKeysFile.new(@container, keyfile.path)
      auth_keys.lockfile = lockfile

      assert_equal(1, auth_keys.authorized_keys.length,
                   "incorrect number of remaining keys before remove")

      # remove all instances of the key regardless of the id
      auth_keys.remove_key('aabbccddeeffgg0011223344556677889900',
                           'ssh-rsa',
                           'keyid1')
      assert_equal(0, auth_keys.authorized_keys.length,
                   "incorrect number of remaining keys after one remove")

    ensure
      keyfile.close
      keyfile.delete

      lockfile.close
      lockfile.delete
    end
      

  end

  def test_replace_keys

    # define the temporary file locations
    lockfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-replace',
                             '-lock']
    keyfile = Tempfile.new ['openshift-origin-node-test-sshauthkey-replace',
                            '-keyfile']

    keyfile_name = keyfile.path

    begin 
      # create a one-line file for replacement
      File.open(keyfile_name, 'w') {|f|
        f.write 'command="/bin/false",no-X11-fowarding ssh-rsa aabbccddeeffgg0011223344556677889900 OPENSHIFT-testuser1-keyid1' + "\n"
      }

      # initialize the authorized keys file

      # create the AuthorizedKeysFile object
      auth_keys = AuthorizedKeysFile.new(@container, keyfile_name)
      auth_keys.lockfile = lockfile

      new_keys = [
                 {'key' => 'AAA', 
                  'type' => 'ssh-rsa', 
                  'comment' => 'id1'
                 },
                 {'key' => 'bar',
                  'type' => 'ssh-rsa',
                  'comment' => 'id2'
                 },
                 {'key' => 'AAA', 
                  'type' => 'ssh-rsa',
                  'comment' => 'id3'}
                 ]
    
      auth_keys.replace_keys(new_keys)

      assert(File.exists? keyfile_name)
      lines = File.open(keyfile_name) {|f|
        f.readlines { |l| l.strip }
      }

      assert_equal(3, lines.length)
      
      # Verify that all lines match format
      lines.each {|l|
        assert_match(/^command=\"\/bin\/bash\",no-X11-forwarding ssh-rsa \w+ \w+/,
                     l)
      }

      # Verify that all three ids are in the result
      assert_match(/id1$/, lines[0])
      assert_match(/id2$/, lines[1])
      assert_match(/id3$/, lines[2])
    end

  end

  def test_replace_keys_with_empty_list
    # define the temporary file locations
    lockfile = Tempfile.new ['openshift-origin-node-test-ssh_authkey-replace-empty',
                             '-lock']
    keyfile = Tempfile.new ['openshift-origin-node-test-ssh_authkey-replace-empty',
                            '-keyfile']
    keyfile_name = keyfile.path

    # create a one-line file for replacement
    File.open(keyfile_name, 'w') {|f|
      f.write 'command="/bin/false",no-X11-fowarding ssh-rsa aabbccddeeffgg0011223344556677889900 OPENSHIFT-testuser1-keyid1' + "\n"
    }

    # create the AuthorizedKeysFile object
    auth_keys = AuthorizedKeysFile.new(@container, keyfile_name)
    auth_keys.lockfile = lockfile

    new_keys = []

    auth_keys.replace_keys(new_keys)

    assert(File.exists? keyfile_name)
    auth_file = File.open(keyfile_name)
    content = auth_file.read
    auth_file.close

    assert_match(/^\n*$/, content,
                  "Authorized keys file is not empty")
  end

  def test_validate_keys

    a = AuthorizedKeysFile.new(@container)
    
    invalid_key_sets = 
      [nil,
       [{'key' => nil}],
       [{'key' => ''}],
       [{'key' => 'a'}],
       [{'type' => nil}],
       [{'type' => ''}],
       [{'type' => 'a'}],
       [{'key' => 'a', 'type' => ''}],
       [{'key' => '', 'type' => 'a'}],
       [{'key' => '', 'type' => 'a', 'comment' => ''}],
       [
        {'key' => 'a', 'type' => 'a'},
        {}
       ],
       [
        {},
        {'key' => 'a', 'type' => 'a'},
       ],
       [
        {'key' => 'a', 'type' => 'a'},
        {},
        {'key' => 'a', 'type' => 'a'}
       ],
      ]
    
    valid_key_sets = 
      [
       [],
       [{'key' => 'a', 'type' => 'a'}],
       [{'key' => 'a', 'type' => 'a', 'comment' => 'a'}],
       [
        {'key' => 'a', 'type' => 'a', 'comment' => 'a'},
        {'key' => 'a', 'type' => 'a', 'comment' => 'a'}
       ],
       [
        {'key' => 'a', 'type' => 'a', 'comment' => 'a'},
        {'key' => 'a', 'type' => 'a', 'comment' => 'a'},
        {'key' => 'a', 'type' => 'a', 'comment' => 'a'},
       ],
      ]

    invalid_key_sets.each {|key_spec|
      assert(!a.send(:validate_keys, key_spec),
             "this key should be invalid: #{key_spec}")
    }

    valid_key_sets.each {|key_spec|
      assert(a.send(:validate_keys, key_spec),
             "this key should be valid: #{key_spec}")
    }
    
  end

  def test_key_id
    a = AuthorizedKeysFile.new(@container)

    comment_string = 'testcomment'
    key_id = a.send(:key_id, comment_string)
    assert_equal("OPENSHIFT-#{@gear_uuid}-#{comment_string}", key_id,
                 "invalid key id produced")
  end

  def test_key_entry
    a = AuthorizedKeysFile.new(@container)

    key_string = 'AAAAAverylongstringofcharacters'
    key_type = 'ssh-rsa'
    comment_string = 'testcomment'
    key_entry = a.send(:key_entry, key_string, key_type, comment_string, nil)

    expected_key_entry = 
      "command=\"#{@container.container_plugin.gear_shell}\"" +
      ",no-X11-forwarding #{key_type} #{key_string} " + 
      a.send(:key_id, comment_string)
    assert_equal(expected_key_entry, key_entry, "invalid key entry produced")

  end

end
