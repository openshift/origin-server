require File.expand_path('../../../test_helper', __FILE__)

class RestApiCartridgeTypeTest < ActiveSupport::TestCase

  def setup
    with_simple_unique_user
  end

  def log_types(types)
    types.each do |t|
      Rails.logger.debug <<-TYPE.strip_heredoc
        Cartridge #{t.display_name} (#{t.name})
          description: #{t.description}
          tags:        #{t.tags.inspect}
          version:     #{t.version}
          provides:    #{t.provides.inspect}
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
    assert types.all?{ |t| t.tags & t.categories = t.categories }
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

    assert types[0].id.starts_with?('jbosseap-'), types[0].id

    assert type = types.find{ |t| t.template.present? }
    template = type.template
    assert template.name
    assert template.description
    assert template.version
    assert template.website
    assert template.git_url
    assert template.git_project_url
    assert_equal type.id, template.name
    assert template.git_project_url
    assert_same template.tags, template.tags
  end
end
