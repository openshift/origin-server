require File.expand_path('../../../test_helper', __FILE__)

class RestApiCartridgeTypeTest < ActiveSupport::TestCase

  def setup
    with_configured_user
  end

  def log_types(types)
    types.each do |t|
      Rails.logger.debug <<-TYPE.strip_heredoc
        Type #{t.display_name} (#{t.id})
          description: #{t.description}
          tags:        #{t.tags.inspect}
          version:     #{t.version}
          cartridges:  #{t.respond_to?(:cartridges) ? t.cartridges.inspect : 'n/a'}
          priority:    #{t.priority}
        #{log_extra(t)}
      TYPE
    end
  end
  def log_extra(type)
    if type.respond_to?(:requires)
      "  requires:    #{type.requires.inspect}\n"
    end
  end

  test 'should load embedded cartridge types from server' do
    types = CartridgeType.embedded
    assert types.length > 0
    types.sort!

    log_types(types)

    assert type = types.find{ |t| t.name.starts_with?('phpmyadmin-') }
    assert type.requires.find{ |r| r.starts_with?('mysql-') }, type.requires.inspect
    assert type.tags.include? :administration
    assert_not_equal type.name, type.display_name

    assert (required = types.select{ |t| t.requires.present? }).length > 1
    assert types.all?{ |t| t.tags.present? }
    assert types.all?{ |t| t.tags.present? }
    assert types.all?{ |t| (t.tags & t.categories).sort.uniq == t.categories.sort.uniq }
  end

  test 'should load standalone cartridge types' do
    types = CartridgeType.standalone
    assert types.length > 0
    types.sort!

    log_types(types)

    assert types[0].name.starts_with?('jbosseap-')
  end

  test 'should load metadata from broker' do
    assert type = CartridgeType.find('zend-5.6')
    assert type.tags.include?(:web_framework), type.tags.inspect
    assert_not_equal type.name, type.display_name
  end

  test 'should load application types' do
    types = ApplicationType.all
    assert types.length > 0

    types.sort!
    log_types(types)

    assert types[0].id.starts_with?('cart!jbosseap'), types[0].id
  end

  test 'sort cartridges' do
    array = ['diy-0.1','mongodb-2.2'].map{ |s| Cartridge.new(:name => s) }
    assert_equal array.map(&:name), array.sort.map(&:name)
  end

  test 'cartridges are sorted properly' do
    ruby18 = CartridgeType.find 'ruby-1.8'
    ruby = CartridgeType.find 'ruby-1.9'
    php = CartridgeType.find 'php-5.3'
    mongo = CartridgeType.find 'mongodb-2.2'
    cron = CartridgeType.find 'cron-1.4'
    jenkins = CartridgeType.find 'jenkins-client-1.4'

    assert ruby18 > ruby
    assert ruby < ruby18

    assert cron > ruby
    assert ruby < cron

    assert mongo < cron
    assert cron > mongo

    assert ruby < mongo
    assert mongo > ruby

    assert php < ruby
    assert ruby > php

    assert php < jenkins
    assert ruby < jenkins
  end

  test 'matching cartridges types' do
    found, missing = ApplicationType.matching_cartridges('php-')
    assert_equal ['php-5.3'], found['php-'].map(&:name), found.inspect
    assert missing.empty?
  end

  test 'match cartridges' do
    assert_equal [], CartridgeType.cached.matches('bra').map(&:name)
    assert_equal ['ruby-1.9','ruby-1.8'], CartridgeType.cached.matches('ruby').map(&:name)
    assert_equal ['ruby-1.9','ruby-1.8'], CartridgeType.cached.matches('ruby*').map(&:name)
    assert_equal ['ruby-1.9','ruby-1.8'], CartridgeType.cached.matches('*uby*').map(&:name)
    assert_equal ['zend-5.6','php-5.3'], CartridgeType.cached.matches('zend-|php-').map(&:name)
    assert_equal ['php-5.3','zend-5.6'], CartridgeType.cached.matches('php-|zend-').map(&:name)
  end
end
