metadata    :name        => "Openshift Origin Management",
            :description => "Agent to manage Openshift Origin services",
            :author      => "Mike McGrath",
            :license     => "ASL 2.0",
            :version     => "0.1",
            :url         => "http://www.openshift.com",
            :timeout     => 60


action "cartridge_do", :description => "run a cartridge action" do
    display :always

    input :cartridge,
        :prompt         => "Cartridge",
        :description    => "Full name and version of the cartridge to run an action on",
        :type           => :string,
        :validation     => '^[a-zA-Z0-9\.\-\/]+$',
        :optional       => false,
        :maxlength      => 64

    input :action,
        :prompt         => "Action",
        :description    => "Cartridge hook to run",
        :type           => :string,
        :validation     => '^(app-create|app-destroy|env-var-add|env-var-remove|broker-auth-key-add|broker-auth-key-remove|authorized-ssh-key-add|authorized-ssh-key-remove|app-state-show|cartridge-list|configure|deconfigure|update-namespace|tidy|deploy-httpd-proxy|remove-httpd-proxy|move|pre-move|post-move|info|post-install|post-remove|pre-install|reload|restart|start|status|stop|force-stop|add-alias|remove-alias|expose-port|conceal-port|show-port|system-messages)$',
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
        :type           => :any,
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
