require File.expand_path('../../test_helper', __FILE__)

module ActiveModelComplianceTest
  [
    RestApi::Base,
    RestApi::Info,
    Key,
    Domain,
    Application,
    Alias,
    Cartridge,
    CartridgeType,
    Embedded,
    Gear,
    GearGroup,
    User,
  ].each do |klass|
    const_set("#{klass.to_s.gsub(':','')}Test", Class.new(ActiveModel::TestCase) do
      include ActiveModel::Lint::Tests
      setup{ @model = klass.new }
    end)
  end
end
