ENV["TEST_NAME"] = "unit_subscription_test"
require File.expand_path('../../test_helper', __FILE__)
require 'openshift-origin-controller'
require 'mocha/setup'

class SubscriptionTest < ActiveSupport::TestCase

  test "environment variable subscription by wildcard" do
    web_cart = mock_wildcard_web_cart
    embed_cart = mock_embed_cart

    CartridgeCache.stubs(:find_cartridge).with('webcart-0.1', is_a(Application)).returns(web_cart)
    CartridgeCache.stubs(:find_cartridge).with('embedcart-0.1', is_a(Application)).returns(embed_cart)
    Moped::BSON::ObjectId.stubs(:new).returns('1','2','3','4','5')

    app = Application.new default_gear_size: nil, scalable: true

    embedcartspec = ComponentSpec.new("embedcart-0.1", "embedcart-0.1")
    webcartspec = ComponentSpec.new("webcart-0.1", "webcart-0.1")

    result = app.elaborate([web_cart, embed_cart])
    expected_result = [[{"from_comp_inst"=>embedcartspec,
                          "to_comp_inst"=>webcartspec,
                          "from_connector_name"=>"publish-db-connection-info",
                          "to_connector_name"=>"set-env",
                          "connection_type"=>"ENV:NET_TCP:db:connection-info"},
                        {"from_comp_inst"=>embedcartspec,
                          "to_comp_inst"=>webcartspec,
                          "from_connector_name"=>"publish-garbage-info",
                          "to_connector_name"=>"set-env",
                          "connection_type"=>"ENV:NET_TCP:garbage:info"}],
                       [
                        GroupOverride.new([webcartspec], 1, -1, nil, 0),
                        GroupOverride.new([embedcartspec], 1, 1, nil, 0)
                       ]
                     ]

    assert_equal(expected_result, result)
  end

  test "environment variable subscription by specific connection type" do
    web_cart = mock_non_wildcard_web_cart
    embed_cart = mock_embed_cart

    CartridgeCache.stubs(:find_cartridge).with('webcart-0.1', is_a(Application)).returns(web_cart)
    CartridgeCache.stubs(:find_cartridge).with('embedcart-0.1', is_a(Application)).returns(embed_cart)
    Moped::BSON::ObjectId.stubs(:new).returns('1','2','3','4','5')

    app = Application.new default_gear_size: nil, scalable: true

    embedcartspec = ComponentSpec.new("embedcart-0.1", "embedcart-0.1")
    webcartspec = ComponentSpec.new("webcart-0.1", "webcart-0.1")

    result = app.elaborate([web_cart, embed_cart])
    expected_result = [[{"from_comp_inst"=>embedcartspec,
                          "to_comp_inst"=>webcartspec,
                          "from_connector_name"=>"publish-db-connection-info",
                          "to_connector_name"=>"set-db-connection-info",
                          "connection_type"=>"ENV:NET_TCP:db:connection-info"}],
                       [
                        GroupOverride.new([webcartspec], 1, -1, nil, 0),
                        GroupOverride.new([embedcartspec], 1, 1, nil, 0)
                       ]
                      ]

    assert_equal(expected_result, result)
  end

  def mock_embed_cart
    embed_cart = mock('OpenShift::Cartridge')
    embed_component = mock('OpenShift::Component')
    embed_cart_name = 'embedcart-0.1'

    embed_cart_requires = []
    embed_cart.stubs(:id).returns('_emb_cart_1_')
    embed_cart.stubs(:requires).returns(embed_cart_requires)
    embed_cart_features = ['embedcart-0.1', 'embedcart', 'embedcart(version) = 0.1']
    embed_cart.stubs(:features).returns(embed_cart_features)
    embed_cart.stubs(:name).returns(embed_cart_name)
    embed_cart_categories = ['service', 'database', 'embedded']
    embed_cart.stubs(:categories).returns(embed_cart_categories)
    embed_cart.stubs(:is_external?).returns(false)
    embed_cart.stubs(:platform).returns('linux')

    embed_publishes_array = []

    embed_connector = mock('OpenShift::Connector')
    embed_connector.stubs(:name => "publish-db-connection-info", :required => false, :type => "ENV:NET_TCP:db:connection-info")
    embed_connector_descriptor = {"Required" => false, "Type" => "ENV:NET_TCP:db:connection-info"}
    embed_connector.stubs(:to_descriptor).returns(embed_connector_descriptor)
    embed_publishes_array << embed_connector

    embed_connector = mock('OpenShift::Connector')
    embed_connector.stubs(:name => "publish-garbage-info", :required => false, :type => "ENV:NET_TCP:garbage:info")
    embed_connector_descriptor = {"Required" => false, "Type" => "ENV:NET_TCP:garbage:info"}
    embed_connector.stubs(:to_descriptor).returns(embed_connector_descriptor)
    embed_publishes_array << embed_connector

    embed_component.stubs(:publishes).returns(embed_publishes_array)

    embed_subscribes_array = []
    embed_component.stubs(:subscribes).returns(embed_subscribes_array)
    embed_component.stubs(:name).returns(embed_cart_name)
    embed_component.stubs(:is_sparse?).returns(false)
    embed_scaling = mock('OpenShift::Scaling')
    embed_scaling.stubs(:max => 1, :min => 1, :min_managed => 0, :multiplier => 1)
    embed_component.stubs(:scaling).returns(embed_scaling)
    embed_cart.stubs(:components).returns([embed_component])
    embed_cart.stubs(:get_component).with(embed_cart_name).returns(embed_component)
    embed_cart.stubs(:group_overrides).returns([])
    embed_cart
  end

  def mock_wildcard_web_cart
    web_connector = mock('OpenShift::Connector')
    web_connector.stubs(:name => "set-env", :required => false, :type => "ENV:*")
    web_connector.stubs(:to_descriptor).returns({"Required" => false, "Type" => "ENV:*"})

    web_cart = web_cart_with_connectors([web_connector])
  end

  def mock_non_wildcard_web_cart
    web_subscribes_array = []

    web_connector = mock('OpenShift::Connector')
    web_connector.stubs(:name => "set-db-connection-info", :required => false, :type => "ENV:NET_TCP:db:connection-info")
    web_connector.stubs(:to_descriptor).returns({"Required" => false, "Type" => "ENV:NET_TCP:db:connection-info"})
    web_subscribes_array << web_connector

    web_connector = mock('OpenShift::Connector')
    web_connector.stubs(:name => "set-nosql-db-connection-info", :required => false, :type => "ENV:NET_TCP:nosqldb:connection-info")
    web_connector.stubs(:to_descriptor).returns({"Required" => false, "Type" => "ENV:NET_TCP:nosqldb:connection-info"})
    web_subscribes_array << web_connector

    web_cart = web_cart_with_connectors(web_subscribes_array)
  end


  def web_cart_with_connectors( web_subscribes_array )
    web_cart = mock('OpenShift::Cartridge')
    web_component = mock('OpenShift::Component')
    web_cart_name = 'webcart-0.1'

    web_cart_requires = []
    web_cart.stubs(:id).returns('_web_cart_1_')
    web_cart.stubs(:requires).returns(web_cart_requires)
    web_cart_features = ['webcart-0.1', 'webcart', 'webcart(version) = 0.1']
    web_cart.stubs(:features).returns(web_cart_features)
    web_cart.stubs(:name).returns(web_cart_name)
    web_cart_categories = ['service', 'webcart', 'web_framework']
    web_cart.stubs(:categories).returns(web_cart_categories)
    web_cart.stubs(:is_external?).returns(false)
    web_cart.stubs(:platform).returns('linux')

    web_publishes_array = []
    web_component.stubs(:publishes).returns(web_publishes_array)
    web_component.stubs(:subscribes).returns(web_subscribes_array)
    web_component.stubs(:name).returns(web_cart_name)
    web_component.stubs(:is_sparse?).returns(false)
    web_scaling = mock('OpenShift::Scaling')
    web_scaling.stubs(:max => -1, :min => 1, :min_managed => 0, :multiplier => 1)
    web_component.stubs(:scaling).returns(web_scaling)

    web_cart.stubs(:components).returns([web_component])
    web_cart.stubs(:get_component).with(web_cart_name).returns(web_component)
    web_cart.stubs(:group_overrides).returns([])
    web_cart
  end

end
