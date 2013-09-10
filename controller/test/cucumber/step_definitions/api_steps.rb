require 'rubygems'
require 'rest_client'
require 'nokogiri'
#require '/var/www/openshift/broker/config/environment'
require 'logger'
require 'parseconfig'
require 'rspec'

$hostname = "localhost"
begin
  if File.exists?("/etc/openshift/node.conf")
    config = ParseConfig.new("/etc/openshift/node.conf")
    val = config["PUBLIC_HOSTNAME"].gsub(/[ \t]*#[^\n]*/,"")
    val = val[1..-2] if val.start_with? "\""
    $hostname = val
  end
rescue
  puts "Unable to determine hostname. Defaulting to #{$hostname}\n"
end

$cloud_domain = "example.com"
begin
  if File.exists?("/etc/openshift/node.conf")
    config = ParseConfig.new("/etc/openshift/node.conf")
    val = config["CLOUD_DOMAIN"].gsub(/[ \t]*#[^\n]*/,"")
    val = val[1..-2] if val.start_with? "\""
    $cloud_domain = val
  end
rescue
  puts "Unable to determine cloud domain. Defaulting to #{$cloud_domain}\n"
end


@random = nil
Before do
  @base_url = "https://#{$hostname}/broker/rest"
end

After do |scenario|
  #domains = ["api#{@random}", "apix#{@random}", "apiY#{@random}", "app-api#{@random}"]
  @random = nil
  (@undo_config || []).each do |(main, secondary, value)|
    Rails.configuration[main.to_sym][secondary.to_sym] = value
  end
end

Given /^a new user, verify updating a domain with an php-([^ ]+) application in it over ([^ ]+) format$/ do |php_version, format|
  steps %{
    Given a new user
    And I accept "#{format}"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-#{php_version}"
    Then the response should be "201"
    When I send a PUT request to "/domains/api<random>" with the following:"name=apix<random>"
    Then the response should be "422"
    And the error message should have "severity=error&exit_code=128"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    When I send a PUT request to "/domains/api<random>" with the following:"name=apix<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "name=apix<random>"
  }
end

Given /^a new user, verify deleting a domain with an php-([^ ]+) application in it over ([^ ]+) format$/ do |php_version, format|
  steps %{
    Given a new user
    And I accept "#{format}"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-#{php_version}"
    Then the response should be "201"
    When I send a DELETE request to "/domains/api<random>"
    Then the response should be "422"
    And the error message should have "severity=error&exit_code=128"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"
  }
end

Given /^a new user, verify force deleting a domain with an php-([^ ]+) application in it over ([^ ]+) format$/ do |php_version, format|
  steps %{
    Given a new user
    And I accept "#{format}"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=php-#{php_version}"
    Then the response should be "201"
    When I send a DELETE request to "/domains/api<random>?force=true"
    Then the response should be "200"
  }
end

Given /^a new user, create a ([^ ]+) application using ([^ ]+) format and verify application state on gear$/ do |cart_name, format|
  steps %{
    Given a new user
    And I accept "#{format}"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=#{cart_name}"
    Then the response should be "201"

    When I send a GET request to "/domains/api<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=started"

    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=stopped"

    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=start"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=started"

    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=started"

    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"
  }
end

Given /^a new user$/ do
  @random = rand(99999999)
  @username = "rest-test-#{@random}"
  @password = "xyz123"

  register_user(@username, @password) if $registration_required

#TODO authenticate user

end

Given /^the Rails ([^\s]+) configuration key ([^\s]+) is "([^\"]*)"$/ do |main, secondary, value|
  (@undo_config ||= []) << [main, secondary, Rails.configuration.config[main.to_sym][secondary.to_sym]]
  Rails.configuration.config[main.to_sym][secondary.to_sym] = value
end

Given /^I send and accept "([^\"]*)"$/ do |type|
  @headers = {:accept => type, :content_type => type}
end

Given /^I accept "([^\"]*)"$/ do |type|
  @accept_type = type
  @headers = {:accept => type.to_s.downcase}
end

Given /^a quickstart UUID$/ do
  path = sub_random('/quickstarts')
  url = @base_url + path.to_s
  @request = RestClient::Request.new(:method => :get, :url => url, :headers => @headers)
  begin
    @response = @request.execute()
  rescue => e
    @response = e.response
  end

  # Get a normalized list of quickstarts
  quickstarts = unpacked_data(@response.body)

  @uuid = quickstarts[0]['quickstart']['id']
end

When /^I send a GET request to "([^\"]*)"$/ do |path|
  path = sub_random(path)
  url = @base_url + path.to_s
  @request = RestClient::Request.new(:method => :get, :url => url,
  :user => @username, :password => @password, :headers => @headers)
  begin
    @response = @request.execute()
  rescue Timeout::Error, RestClient::RequestTimeout => e
    raise Exception.new("#{e.message}: #{@request.method} #{@request.url} timed out")
  rescue RestClient::ExceptionWithResponse => e
    @response = e.response
  end
end

When /^I send an unauthenticated GET request to "([^\"]*)"$/ do |path|
  path = sub_random(sub_uuid(path))
  url = @base_url + path.to_s
  @request = RestClient::Request.new(:method => :get, :url => url, :headers => @headers)
  begin
    @response = @request.execute()
  rescue Timeout::Error, RestClient::RequestTimeout => e
    raise Exception.new("#{e.message}: #{@request.method} #{@request.url} timed out")
  rescue RestClient::ExceptionWithResponse => e
    @response = e.response
  end
end

When /^I send a POST request to "([^\"]*)" with the following:"([^\"]*)"$/ do |path, body|
  path = sub_random(path)
  body = sub_random(body)
  #puts "path #{path}"
  #puts "body #{body}"
  payload = {}
  params = body.split("&")
  params.each do |param|
    key, value = param.split("=", 2)
    if payload[key].nil?
       payload[key] = value
    else
      values = [payload[key], value]
      payload[key] = values.flatten
    end
  end
  url = @base_url + path.to_s
  @request = RestClient::Request.new(:method => :post, :url => url,
  :user => @username, :password => @password, :headers => @headers,
  :payload => payload, :timeout => 180)
  begin
    @response = @request.execute()
  rescue Timeout::Error, RestClient::RequestTimeout => e
    @request.inspect
    raise Exception.new("#{e.message}: #{@request.method} #{@request.url} with payload #{@request.payload} timed out")
  rescue RestClient::ExceptionWithResponse => e
    @response = e.response
  end
end

When /^I send a PUT request to "([^\"]*)" with the following:"([^\"]*)"$/ do |path, body|
  path = sub_random(path)
  body = sub_random(body)
  #puts "path #{path}"
  #puts "body #{body}"
  payload = {}
  params = body.split("&")
  params.each do |param|
    key, value = param.split("=", 2)
    payload[key] = value
  end
  url = @base_url + path.to_s
  @request = RestClient::Request.new(:method => :put, :url => url,
  :user => @username, :password => @password, :headers => @headers,
  :payload => payload, :timeout => 180)
  begin
    @response = @request.execute()
  rescue Timeout::Error, RestClient::RequestTimeout => e
    @request.inspect
    raise Exception.new("#{e.message}: #{@request.method} #{@request.url} with payload #{@request.payload} timed out")
  rescue RestClient::ExceptionWithResponse => e
    @response = e.response
  end
end

When /^I send a DELETE request to "([^\"]*)"$/ do |path|
  path = sub_random(path)
  #puts "path #{path}"

  url = @base_url + path.to_s
  @request = RestClient::Request.new(:method => :delete, :url => url,
  :user => @username, :password => @password, :headers => @headers)
  begin
    @response = @request.execute()
  rescue Timeout::Error, RestClient::RequestTimeout => e
    raise Exception.new("#{e.message}: #{@request.method} #{@request.url} timed out")
  rescue RestClient::ExceptionWithResponse => e
    @response = e.response
  end
end

Then /^the response should be "([^\"]*)"$/ do |status|
  puts "#{@response.body}"  if @response.code != status.to_i
  @response.code.should == status.to_i
end

Then /^the response should have the link(?:s)? "([^\"]*)"$/ do |link|
  response_acceptable = false
  link_names = link.split(",")
  missing_names = link_names.select do |name|
    if link = links[name.strip]
      URI.parse(link['href'])
      !link['method'] || !link['rel'] || !link['required_params']
    else
      true
    end
  end
  raise "Response did not contain link(s) #{missing_names.join(", ")}" unless missing_names.empty?
  true
end

Then /^the response should be one of "([^\"]*)"$/ do |acceptable_statuses|
  response_acceptable = false
  statuses = acceptable_statuses.split(",")
  statuses.each do | status|
    if @response.code == status.to_i
      response_acceptable = true 
      break
    end
  end
  puts "#{@response.body}"  unless response_acceptable
  response_acceptable.should == true
end

Then /^the response should be a "([^\"]*)" with attributes "([^\"]*)"$/ do |tag, attributes_str|
  attributes_str = sub_random(attributes_str)
  attributes_array = attributes_str.split("&")
  if @accept_type.upcase == "XML"
    #puts @response.body
    result = Nokogiri::XML(@response.body)
    attributes_array.each do |attributes|
      key, value = attributes.split("=", 2)
      #puts "#{result.xpath("//#{tag}/#{key}").text} #{value}"
      result.xpath("//#{tag}/#{key}").text.should == value
    end
  elsif @accept_type.upcase == "JSON"
    result = JSON.parse(@response.body)
    obj = result["data"]
    tag = tag.split("/").each do |t|
      case obj.class.to_s
        when 'Hash'
          obj = obj[t] unless obj[t].nil?
        when 'Array'
          obj = obj.first
      end
    end
    attributes_array.each do |attributes|
      key, value = attributes.split("=", 2)
      obj[key].should == value
    end
  else
  false
  end
end

Then /^the response should be a list of "([^\"]*)" with attributes "([^\"]*)"$/ do |tag, attributes_str|
  attributes_str = sub_random(attributes_str)
  attributes_array = attributes_str.split("&")
  if @accept_type.upcase == "XML"
    #puts @response.body
    result = Nokogiri::XML(@response.body)
    attributes_array.each do |attributes|
      key, value = attributes.split("=", 2)
      #puts "#{result.xpath("//#{tag}/#{key}").text} #{value}"
      result.xpath("//#{tag}/#{key}").text.should == value
    end
  elsif @accept_type.upcase == "JSON"
    result = JSON.parse(@response.body)
    obj = result["data"]
    attributes_array.each do |attributes|
      key, value = attributes.split("=", 2)
      obj[key].should == value
    end
  else
  false
  end
end

Then /^the error message should have "([^\"]*)"$/ do |attributes_str|
  attributes_str = sub_random(attributes_str)
  attributes_array = attributes_str.split("&")
  if @accept_type.upcase == "XML"
    #puts @response.body
    result = Nokogiri::XML(@response.body)
    messages = result.xpath("//message")
    #puts messages
    attributes_array.each do |attributes|
      key, value = attributes.split("=", 2)
      key = key.sub("_", "-")
      messages.each do |message|
        #puts message
        #puts message.xpath("#{key}").text
        message.xpath("#{key}").text.should == value
      end
    end
  elsif @accept_type.upcase == "JSON"
    result = JSON.parse(@response.body)
    messages = result["messages"]
    attributes_array.each do |attributes|
      key, value = attributes.split("=", 2)
      messages.each do |message|
        message[key].to_s.should == value
      end
    end
  else
  false
  end
end

Then /^the response descriptor should have "([^\"]*)" as dependencies$/ do |deps|
  #puts @response.body
  if @accept_type.upcase == "XML"
    page = Nokogiri::XML(@response.body)
    desc_yaml = page.xpath("//response/data/datum")
    desc = YAML.load(desc_yaml.text.to_s)
  elsif @accept_type.upcase == "JSON"
    page = JSON.parse(@response.body)
    desc_yaml = page["data"]
    desc = YAML.load(desc_yaml)
  end
  #desc = YAML.load(desc_yaml.text.to_s)
  deps.split(",").each do |dep|
    desc["Requires"].include?(dep).should
  end
end

Then /^the response should be a list of "([^\"]*)"$/ do |list_type|
  items = unpacked_data(@response.body)
  if items.length < 1
    raise("I got an empty list of #{list_type}")
  end
  if list_type == 'cartridges'
    items.each do |cartridge|
      check_cartridge(cartridge)
    end
  elsif list_type == 'quickstarts'
    items.each do |item|
      check_quickstart(item)
    end
  else
    raise("I don't recognize list type #{list_type}")
  end
end

Then /^the response should be a "([^\"]*)"$/ do |item_type|
  item = unpacked_data(@response.body)[0]
  if item_type == 'cartridge'
    check_cartridge(item)
  elsif item_type == 'quickstart'
    check_quickstart(item)
  else
    raise("I don't recognize item type #{item_type}")
  end
end

def check_cartridge(cartridge)
  unless cartridge.has_key?("name") && cartridge['name'].match(/\S+/)
    raise("I found a cartridge without a name")
  end
end

def check_quickstart(quickstart)
  unless quickstart.has_key?("quickstart") && quickstart['quickstart'].has_key?("id") && quickstart['quickstart']['id'].match(/\S+/)
    raise("I found a quickstart without an ID")
  end
end

# Gets a normalized response
def unpacked_data(response_body)
  if @accept_type.upcase == 'JSON'
    data = JSON.parse(@response.body)['data']
  elsif @accept_type.upcase == 'XML'
    data = Hash.from_xml(@response.body)['response']['data']['template']
  end
  return data.is_a?(Array) ? data : [data]
end

def sub_random(value)
  if value and value.include? "<random>"
    value = value.gsub("<random>", @random.to_s)
  end
  return value
end

def sub_uuid(value)
  if value and value.include? "<uuid>"
    value = value.sub("<uuid>", @uuid)
  end
  return value
end

def links
  @links ||= if @accept_type.upcase == "JSON"
      result = JSON.parse(@response.body)['data']
    end
end
