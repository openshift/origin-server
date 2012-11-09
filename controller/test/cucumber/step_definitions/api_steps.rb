require 'rubygems'
require 'rest_client'
require 'nokogiri'
#require '/var/www/openshift/broker/config/environment'
require 'logger'

@random = nil
Before do
  @base_url = "https://localhost/broker/rest"
end

After do |scenario|
  domains = ["api#{@random}", "apiX#{@random}", "apiY#{@random}", "app-api#{@random}"]
  remove_dns_entries(domains)
  @random = nil
end

Given /^a new user$/ do
  @random = rand(99999999)
  @username = "rest-test-#{@random}"
  @password = "xyz123"
  
  register_user(@username, @password) if $registration_required

#TODO authenticate user

end

Given /^I send and accept "([^\"]*)"$/ do |type|
  @headers = {:accept => type, :content_type => type}
end

Given /^I accept "([^\"]*)"$/ do |type|
  @accept_type = type
  @headers = {:accept => type.to_s.downcase}
end

Given /^an application template UUID$/ do
  path = sub_random('/application_templates')
  url = @base_url + path.to_s
  @request = RestClient::Request.new(:method => :get, :url => url, :headers => @headers)
  begin
    @response = @request.execute()
  rescue => e
    @response = e.response
  end
  
  # Get a normalized list of templates
  application_templates = unpacked_data(@response.body)

  @application_template_uuid = application_templates[0]['uuid']
end

When /^I send a GET request to "([^\"]*)"$/ do |path|
  path = sub_random(path)
  url = @base_url + path.to_s
  @request = RestClient::Request.new(:method => :get, :url => url,
  :user => @username, :password => @password, :headers => @headers)
  begin
    @response = @request.execute()
  rescue => e
  @response = e.response
  end
end

When /^I send an unauthenticated GET request to "([^\"]*)"$/ do |path|
  path = sub_random(sub_uuid(path))
  url = @base_url + path.to_s
  @request = RestClient::Request.new(:method => :get, :url => url, :headers => @headers)
  begin
    @response = @request.execute()
  rescue => e
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
  :payload => payload)
  begin
    @response = @request.execute()
  rescue => e
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
  :payload => payload)
  begin
    @response = @request.execute()
  rescue => e
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
  rescue => e
  @response = e.response
  end
end

Then /^the response should be "([^\"]*)"$/ do |status|
  puts "#{@response.body}"  if @response.code != status.to_i
  @response.code.should == status.to_i
end

Then /^the response should be one of "([^\"]*)"$/ do |acceptable_statuses|
  response_acceptable = false
  statuses = acceptable_statuses.split(",")
  statuses.each do | status|
    puts "#{@response.body}"  if @response.code != status.to_i
    response_acceptable = true unless @response.code != status.to_i
  end
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
    desc_yaml = page.xpath("//response/data")
    desc = YAML.load(desc_yaml.text.to_s)
  elsif @accept_type.upcase == "JSON"
    page = JSON.parse(@response.body)
    desc_yaml = page["data"]
    desc = YAML.load(desc_yaml)
  end
  #desc = YAML.load(desc_yaml.text.to_s)
  deps.split(",").each do |dep|
    desc["Requires"].should include(dep)
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
  elsif list_type == 'application templates'
    items.each do |application_template|
      check_application_template(application_template)
    end
  else
    raise("I don't recognize list type #{list_type}")
  end
end

Then /^the response should be a "([^\"]*)"$/ do |item_type|
  item = unpacked_data(@response.body)
  if item_type == 'cartridge'
    check_cartridge(item)
  elsif item_type == 'application template'
    check_application_template(item)
  else
    raise("I don't recognize item type #{item_type}")
  end
end

def check_cartridge(cartridge)
  unless cartridge.has_key?("name") && cartridge['name'].match(/\S+/)
    raise("I found a cartridge without a name")
  end
end

def check_application_template(application_template)
  unless application_template.has_key?("uuid") && application_template['uuid'].match(/\S+/)
    raise("I found an application without a UUID")
  end
end

# Gets a normalized response
def unpacked_data(response_body)
  if @accept_type.upcase == 'JSON'
    data = JSON.parse(@response.body)['data']
  elsif @accept_type.upcase == 'XML'
    data = Hash.from_xml(@response.body)['response']['data']['template']
  end
  data
end

def sub_random(value)
  if value and value.include? "<random>"
    value = value.sub("<random>", @random.to_s)
  end
  return value
end

def sub_uuid(value)
  if value and value.include? "<uuid>"
    value = value.sub("<uuid>", @application_template_uuid)
  end
  return value
end  