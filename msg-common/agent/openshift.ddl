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
        :type           => :string,
        :validation     => '^(app-create|app-destroy|env-var-add|env-var-remove|broker-auth-key-add|broker-auth-key-remove|authorized-ssh-key-add|authorized-ssh-key-remove|authorized-ssh-keys-replace|app-state-show|cartridge-list|configure|post-configure|deconfigure|unsubscribe|tidy|deploy-httpd-proxy|remove-httpd-proxy|info|post-install|post-remove|pre-install|reload|restart|start|status|stop|force-stop|add-alias|remove-alias|threaddump|expose-port|conceal-port|show-port|frontend-backup|frontend-restore|frontend-create|frontend-destroy|frontend-update-name|frontend-connect|frontend-disconnect|frontend-connections|frontend-idle|frontend-unidle|frontend-check-idle|frontend-sts|frontend-no-sts|frontend-get-sts|aliases|ssl-cert-add|ssl-cert-remove|ssl-certs|frontend-to-hash|system-messages|connector-execute|get-quota|set-quota)$',
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

action "execute_parallel", :description => "run commands in parallel" do
    display :always
    output  :output,
            :description => "Output from script",
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

action "set_district", :description => "run a cartridge action" do
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

action "has_app", :description => "Does this server contain a specified app?" do
    display :always

    input :uuid,
        :prompt         => "Application uuid",
        :description    => "Application uuid",
        :type           => :string,
        :validation     => '^[a-zA-Z0-9]+$',
        :optional       => false,
        :maxlength      => 32

    input :application,
        :prompt         => "Application Name",
        :description    => "Name of an application to search for",
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
