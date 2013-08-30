metadata    :name        => "Openshift Origin Management",
            :description => "Agent to manage Openshift Origin services",
            :author      => "Mike McGrath",
            :license     => "ASL 2.0",
            :version     => "0.1",
            :url         => "http://www.openshift.com",
            :timeout     => 360


action "cartridge_do", :description => "run a cartridge action" do
    display :always

    input :cartridge,
        :prompt         => "Cartridge",
        :description    => "Full name and version of the cartridge to run an action on",
        :type           => :string,
        :validation     => '\A[a-zA-Z0-9\.\-\/_]+\z',
        :optional       => false,
        :maxlength      => 64

    input :action,
        :prompt         => "Action",
        :description    => "Cartridge hook to run",
        :type           => :list,
        :list           => %w(
                              add-alias
                              aliases
                              app-create
                              app-destroy
                              app-state-show
                              authorized-ssh-key-add
                              authorized-ssh-key-remove
                              authorized-ssh-keys-replace
                              broker-auth-key-add
                              broker-auth-key-remove
                              cartridge-list
                              conceal-port
                              configure
                              connector-execute
                              deconfigure
                              deploy-httpd-proxy
                              env-var-add
                              env-var-remove
                              expose-port
                              force-stop
                              frontend-backup
                              frontend-check-idle
                              frontend-connect
                              frontend-connections
                              frontend-create
                              frontend-destroy
                              frontend-disconnect
                              frontend-get-sts
                              frontend-idle
                              frontend-no-sts
                              frontend-restore
                              frontend-sts
                              frontend-to-hash
                              frontend-unidle
                              frontend-update-name
                              get-quota
                              info
                              post-configure
                              post-install
                              post-remove
                              pre-install
                              reload
                              remove-alias
                              remove-httpd-proxy
                              restart
                              set-quota
                              show-port
                              ssl-cert-add
                              ssl-cert-remove
                              ssl-certs
                              start
                              status
                              stop
                              system-messages
                              threaddump
                              tidy
                              user-var-add
                              user-var-remove
                              user-var-list
                              unsubscribe
                              update-cluster
                              ),
        :optional       => false,
        :maxlength      => 64

    input :args,
        :prompt         => "Args",
        :description    => "Args to pass to cartridge",
        :type           => :any,
        :optional       => true

    output  :time,
            :description => "The time as a message",
            :display_as => "Time"

    output  :output,
            :description => "Output from script",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "get_facts", :description => "get a specific list of facts" do
    display :always

    input :facts,
        :prompt         => "Facts",
        :description    => "Enumerable list of fact names for which to retrieve values",
        :type           => :any,
        :optional       => false

    output :output,
        :description    => "A hash of facts and their values",
        :display_as     => "Facts"
end

action "execute_parallel", :description => "run commands in parallel" do
    display :always
    output  :output,
            :description => "Output from script",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "get_all_gears_endpoints", :description => "get ports info about all gears" do
    display :always
    output  :output,
            :description => "Gear external ports information",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "get_all_gears", :description => "get info about all gears" do
    display :always
    output  :output,
            :description => "Gear information",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "get_all_active_gears", :description => "get all the active gears" do
    display :always
    output  :output,
            :description => "Active gears",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "get_all_gears_sshkeys", :description => "get all sshkeys for all gears" do
    display :always
    output  :output,
            :description => "Gear ssh keys",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "set_district", :description => "Set the District of a Node" do
    display :always

    input :uuid,
        :prompt         => "District uuid",
        :description    => "District uuid",
        :type           => :string,
        :validation     => '^[a-zA-Z0-9]+$',
        :optional       => false,
        :maxlength      => 32
        
    input :active,
        :prompt         => "District active boolean",
        :description    => "District active boolean",
        :type           => :boolean,
        :optional       => false

    input :first_uid,
        :prompt         => "First uid",
        :description    => "First uid",
        :type           => :integer,
        :optional       => false

    input :max_uid,
        :prompt         => "Max uid",
        :description    => "Max uid",
        :type           => :integer,
        :optional       => false

    output  :time,
            :description => "The time as a message",
            :display_as => "Time"

    output  :output,
            :description => "Output from script",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "set_district_uid_limits", :description => "Set District uid limits for a Node" do
    display :always

    input :first_uid,
        :prompt         => "First uid",
        :description    => "First uid",
        :type           => :integer,
        :optional       => false

    input :max_uid,
        :prompt         => "Max uid",
        :description    => "Max uid",
        :type           => :integer,
        :optional       => false

    output  :time,
            :description => "The time as a message",
            :display_as => "Time"

    output  :output,
            :description => "Output from script",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "has_gear", :description => "Does this server contain a specified gear?" do
    display :always

    input :uuid,
        :prompt         => "Gear uuid",
        :description    => "Gear uuid",
        :type           => :string,
        :validation     => '^[a-zA-Z0-9]+$',
        :optional       => false,
        :maxlength      => 32

    output  :time,
            :description => "The time as a message",
            :display_as => "Time"

    output  :output,
            :description => "true or false",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "has_embedded_app", :description => "Does this server contain a specified embedded app?" do
    display :always

    input :uuid,
        :prompt         => "Application uuid",
        :description    => "Application uuid",
        :type           => :string,
        :validation     => '^[a-zA-Z0-9]+$',
        :optional       => false,
        :maxlength      => 32

    input :embedded_type,
        :prompt         => "Embedded Type",
        :description    => "Type of embedded application",
        :type           => :string,
        :validation     => '^.+$',
        :optional       => false,
        :maxlength      => 32

    output  :time,
            :description => "The time as a message",
            :display_as => "Time"

    output  :output,
            :description => "true or false",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "get_gear_envs", :description => "Returns the gear's env hash" do
    display :always

    input :uuid,
        :prompt         => "Application uuid",
        :description    => "Application uuid",
        :type           => :string,
        :validation     => '^[a-zA-Z0-9]+$',
        :optional       => false,
        :maxlength      => 32

    output  :time,
            :description => "The time as a message",
            :display_as => "Time"

    output  :output,
            :description => "hash",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "has_uid_or_gid", :description => "Returns whether this system has already taken the uid or gid" do
    display :always

    input :uid,
        :prompt         => "uid/gid",
        :description    => "uid/gid",
        :type           => :number,
        :optional       => false

    output  :time,
            :description => "The time as a message",
            :display_as => "Time"

    output  :output,
            :description => "true or false",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action "has_app_cartridge", :description => "Does this application contain the specified cartridge on the gear?" do
    display :always

    input :app_uuid,
        :prompt         => "Application uuid",
        :description    => "Application uuid",
        :type           => :string,
        :validation     => '^[a-zA-Z0-9]+$',
        :optional       => false,
        :maxlength      => 32

    input :gear_uuid,
        :prompt         => "Gear uuid",
        :description    => "Gear uuid",
        :type           => :string,
        :validation     => '^[a-zA-Z0-9]+$',
        :optional       => false,
        :maxlength      => 32

    input :cartridge,
        :prompt         => "Cartridge",
        :description    => "Full name and version of the cartridge to run an action on",
        :type           => :string,
        :validation     => '\A[a-zA-Z0-9\.\-\/_]+\z',
        :optional       => false,
        :maxlength      => 64

    output  :time,
            :description => "The time as a message",
            :display_as => "Time"

    output  :output,
            :description => "true or false",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end

action 'cartridge_repository', :description => 'perform given operation on a cartridge repository' do
  display :always

  input :action,
        :prompt      => 'Action',
        :description => 'Operation to perform on cartridge repository',
        :type        => :list,
        :list        => %w(install list erase),
        :optional    => false

  input :path,
        :prompt      => 'Cartridge Source',
        :description => 'Full path to cartridge source',
        :type        => :string,
        :validation  => '^/.*$',
        :optional    => true,
        :maxlength   => 2056

  input :name,
        :prompt      => 'Cartridge Name',
        :description => 'Cartridge Name to Remove',
        :type        => :string,
        :validation  => '^[A-Za-z\d]+$',
        :optional    => true,
        :maxlength   => 64

  input :version,
        :prompt      => 'Software Version',
        :description => 'Version for Software packaged by cartridge',
        :type        => :string,
        :validation  => '^\d+[\\.\d]*$',
        :optional    => true,
        :maxlength   => 64

  input :cartridge_version,
        :prompt      => 'Cartridge Version',
        :description => 'Cartridge Version number',
        :type        => :string,
        :validation  => '^\d+[\\.\d]*$',
        :optional    => true,
        :maxlength   => 64
end

action "echo", :description => "echo's a string back" do
    display :always

    input :msg,
        :prompt         => "prompt when asking for information",
        :description    => "description of input",
        :type           => :string,
        :validation     => '^.+$',
        :optional       => false,
        :maxlength      => 90

    output  :msg,
            :description => "displayed message",
            :display_as => "Message"

    output  :time,
            :description => "the time as a message",
            :display_as => "Time"
end

action "upgrade", :description => "upgrade a gear" do
    display :always

    input :uuid,
        :prompt         => "Gear uuid",
        :description    => "Gear uuid",
        :type           => :string,
        :validation     => '^[a-zA-Z0-9]+$',
        :optional       => false,
        :maxlength      => 32

    input :app_uuid,
        :prompt         => "Application uuid",
        :description    => "Application uuid",
        :type           => :string,
        :validation     => '^[a-zA-Z0-9]+$',
        :optional       => false,
        :maxlength      => 32
                
    input :secret_token,
        :prompt         => "Application secret token",
        :description    => "Application secret token",
        :type           => :string,
        :validation     => '^[\w\-]+$',
        :optional       => false,
        :minlength      => 128,
        :maxlength      => 128
                
    input :namespace,
        :prompt         => "Namespace",
        :description    => "Namespace",
        :type           => :string,
        :validation     => '^.+$',
        :optional       => false,
        :maxlength      => 32

    input :version,
        :prompt         => "Target Version",
        :description    => "Target version",
        :type           => :string,
        :validation     => '^.+$',
        :optional       => false,
        :maxlength      => 64

    input :ignore_cartridge_version,
        :prompt         => "Ignore Cartridge Version",
        :description    => "Do not skip upgrade if Cartridge Versions match",
        :type           => :list,
        :optional       => false,
        :list           => ["true", "false"]

    output  :time,
            :description => "The time as a message",
            :display_as => "Time"

    output  :output,
            :description => "Output from script",
            :display_as => "Output"

    output :exitcode,
           :description => "Exit code",
           :display_as => "Exit Code"
end
