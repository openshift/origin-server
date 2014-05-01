module Fixtures
  module Applications
    def self.list
      [
        Application.new({
          :name => 'widgetsprod', :app_url => "http://widgetsprod-widgets.rhcloud.com", :id => '1', :domain_id => 'widgets', :gear_profile => 'small', :gear_count => 2,
          :cartridges => [
            Cartridge.new(:name => 'php-5.3',   :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :supported_scales_from => 1, :supported_scales_to => -1),
            Cartridge.new(:name => 'mysql-5.1', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1),
            Cartridge.new(:name => 'haproxy-1.4', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => ['php-5.3']),
          ],
          :aliases => [Alias.new(:name => 'www.widgets.com'), Alias.new(:name => 'widgets.com')],
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)],
        }, true),
        Application.new({
          :name => 'widgets', :app_url => "http://widgets-widgets.rhcloud.com",:id => '2', :domain_id => 'widgets', :gear_profile => 'small', :gear_count => 1,
          :cartridges => [
            Cartridge.new(:name => 'php-5.3',   :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => ['mysql-5.1']),
            Cartridge.new(:name => 'mysql-5.1', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => ['php-5.3']),
          ],
          :aliases => [],
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)]
        }, true),
        Application.new({
          :name => 'status', :app_url => "http://status-bobdev.rhcloud.com", :id => '3', :domain_id => 'bobdev', :gear_profile => 'small', :gear_count => 1,
          :cartridges => [
            Cartridge.new(:name => 'ruby-1.9',   :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => []),
          ],
          :aliases => [],
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)]
        }, true),
        Application.new({
          :name => 'statusp', :app_url => "http://statusp-bobdev.rhcloud.com",:id => '4', :domain_id => 'bobdev', :gear_profile => 'medium', :gear_count => 10,
          :cartridges => [
            Cartridge.new(:name => 'ruby-1.9',   :gear_profile => 'medium', :current_scale => 9, :scales_from => 5, :scales_to => 10, :supported_scales_from => 1, :supported_scales_to => -1, :colocated_with => ['haproxy-1.4']),
            Cartridge.new(:name => 'haproxy-1.4', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => ['ruby-1.9']),
          ],
          :aliases => [],
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)]
        }, true),
        medium_scale,
        Application.new({
          :name => 'jenkins', :app_url => "http://jenkins-bobdev.rhcloud.com", :id => '3', :domain_id => 'bobdev', :gear_profile => 'small', :gear_count => 1,
          :cartridges => [
            Cartridge.new(:name => 'jenkins-1.4',   :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => []),
          ],
          :aliases => [],
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)]
        }, true),
      ]
    end

    def self.list_domains
      [
        Domain.new({
          :name => 'widgets',
          :application_count => 2,
          :gear_counts => {:small => 1, :medium => 2},
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)],
        }),
        Domain.new({
          :name => 'bobdev',
          :application_count => 3,
          :gear_counts => {:small => 10, :medium => 3, :large => 2},
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)],
        }),
        Domain.new({
          :name => 'foo',
          :application_count => 0,
          :members => [Member.new(:id => '2', :role => 'admin', :name => 'Alice', :owner => true)],
        }),
        Domain.new({
          :name => 'barco',
          :application_count => 0,
          :members => [Member.new(:id => '2', :role => 'admin', :name => 'Bob', :owner => true), Member.new(:id => '1', :role => 'edit', :name => 'Alice', :owner => false)]
        }),
      ]
    end

    def self.medium_scale
      Application.new({
        :name => 'prodmybars', :app_url => "http://prodmybars-barco.rhcloud.com", :id => '5', :domain_id => 'barco', :gear_profile => 'small', :gear_count => 4,
        :creation_time => 1.hour.ago,
        :cartridges => [
          Cartridge.new(:name => 'python-2.7',  :scales_with => 'haproxy-1.4', :gear_profile => 'small', :current_scale => 2, :scales_from => 2, :scales_to => 10, :supported_scales_from => 1, :supported_scales_to => -1, :collocated_with => ['python-2.7', 'jenkins-client-1', 'haproxy-1.4']),
          Cartridge.new(:name => 'mongodb-2.4', :gear_profile => 'large', :current_scale => 3, :scales_from => 3, :scales_to => 3, :supported_scales_from => 3, :supported_scales_to => -1),
          Cartridge.new(:name => 'scalable-1.0', :gear_profile => 'medium', :current_scale => 2, :scales_from => 1, :scales_to => 3, :supported_scales_to => 5),
          Cartridge.new(:name => 'haproxy-1.4', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :collocated_with => ['python-2.7', 'jenkins-client-1', 'haproxy-1.4']),
          Cartridge.new(:name => 'jenkins-client-1', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :collocated_with => ['python-2.7', 'jenkins-client-1', 'haproxy-1.4']),
          Cartridge.new(
            :url => 'http://foo.cart.com/manifest.yml', 
            :license => "Test",
            :license_url => 'mylicenseurl',
            :website => 'mywebsite',
            :help_topics => {"Link1" => 'https://securelink', "Link2" => 'test'},
            :name => 'external-0-gears', :display_name => 'External', :description => 'some external cartridge', :current_scale => 0, :scales_from => 0, :scales_to => 0),
        ],
        :gear_groups => [
          GearGroup.new({:id => '1', :gear_profile => 'small', :gears => [
              Gear.new(:id => 'g1', :state => :started),
              Gear.new(:id => 'g2', :state => :deploying),
            ],
            :cartridges => [
              Cartridge.new({:name => 'haproxy-1.4'}, true),
              Cartridge.new({:name => 'jenkins-client-1'}, true),
              Cartridge.new({:name => 'python-2.7'}, true),
            ],
          }, true),
          GearGroup.new({:id => '2', :gear_profile => 'large', :gears => [
              Gear.new(:id => 'g3', :state => 'started'),
              Gear.new(:id => 'g4', :state => 'idle'),
              Gear.new(:id => 'g5', :state => 'stopped'),
            ],
            :cartridges => [
              Cartridge.new({:name => 'mongodb-2.4'}, true),
            ],
          }, true),
          GearGroup.new({:id => '3', :gear_profile => 'medium', :gears => [
              Gear.new(:id => 'g6', :state => 'started'),
              Gear.new(:id => 'g7', :state => 'started'),
            ],
            :cartridges => [
              Cartridge.new({:name => 'scalable-1.0'}, true),
            ],
          }, true),
        ],
        :aliases => [Alias.new(:name => 'api.mybars.com')],
        :members => [Member.new(:id => '2', :role => 'admin', :name => 'Bob', :owner => true), Member.new(:id => '1', :role => 'edit', :name => 'Alice', :owner => false)]
      }, true)
    end

    def self.xss
      Application.new({
        :name => 'prodmybars', :app_url => "http://prodmybars-barco.rhcloud.com", :id => '5', :domain_id => 'barco', :gear_profile => 'small', :gear_count => 4,
        :creation_time => 1.hour.ago,
        :cartridges => [
          Cartridge.new(:name => 'python-2.7',  :scales_with => 'haproxy-1.4', :gear_profile => 'small', :current_scale => 2, :scales_from => 2, :scales_to => 10, :supported_scales_from => 1, :supported_scales_to => -1, :collocated_with => ['python-2.7', 'jenkins-client-1', 'haproxy-1.4']),
          Cartridge.new(:name => 'mongodb-2.4', :gear_profile => 'large', :current_scale => 3, :scales_from => 3, :scales_to => 3, :supported_scales_from => 3, :supported_scales_to => -1),
          Cartridge.new(:name => 'scalable-1.0', :gear_profile => 'medium', :current_scale => 2, :scales_from => 1, :scales_to => 3, :supported_scales_to => 5),
          Cartridge.new(:name => 'haproxy-1.4', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :collocated_with => ['python-2.7', 'jenkins-client-1', 'haproxy-1.4']),
          Cartridge.new(:name => 'jenkins-client-1', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :collocated_with => ['python-2.7', 'jenkins-client-1', 'haproxy-1.4']),
          Cartridge.new(
            :url => 'javascript:alert(1)',
            :license => "Test",
            :license_url => 'javascript:alert(2)',
            :website => 'javascript:alert(3)',
            :help_topics => {"Link1" => 'javascript:alert(1)', "Link2" => 'test'},
            :name => 'external-0-gears', :display_name => 'External', :description => 'some external cartridge', :current_scale => 0, :scales_from => 0, :scales_to => 0),
        ],
        :gear_groups => [
          GearGroup.new({:id => '1', :gear_profile => 'small', :gears => [
              Gear.new(:id => 'g1', :state => :started),
              Gear.new(:id => 'g2', :state => :deploying),
            ],
            :cartridges => [
              Cartridge.new({:name => 'haproxy-1.4'}, true),
              Cartridge.new({:name => 'jenkins-client-1'}, true),
              Cartridge.new({:name => 'python-2.7'}, true),
            ],
          }, true),
          GearGroup.new({:id => '2', :gear_profile => 'large', :gears => [
              Gear.new(:id => 'g3', :state => 'started'),
              Gear.new(:id => 'g4', :state => 'idle'),
              Gear.new(:id => 'g5', :state => 'stopped'),
            ],
            :cartridges => [
              Cartridge.new({:name => 'mongodb-2.4'}, true),
            ],
          }, true),
          GearGroup.new({:id => '3', :gear_profile => 'medium', :gears => [
              Gear.new(:id => 'g6', :state => 'started'),
              Gear.new(:id => 'g7', :state => 'started'),
            ],
            :cartridges => [
              Cartridge.new({:name => 'scalable-1.0'}, true),
            ],
          }, true),
        ],
        :aliases => [Alias.new(:name => 'api.mybars.com')],
        :members => [Member.new(:id => '2', :role => 'admin', :name => 'Bob', :owner => true), Member.new(:id => '1', :role => 'edit', :name => 'Alice', :owner => false)]
      }, true)
    end    
  end
end