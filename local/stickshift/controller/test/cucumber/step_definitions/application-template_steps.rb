Given /^there are no templates$/ do
  `mongo openshift_broker_dev --eval "db.template.drop()"`
end

When /^I add a new template named '([^\']*)' with dependencies: '([^\']*)' and git repository '([^\']*)' and tags '([^\']*)' consuming (\d+) gear and metadata '([^\']*)'$/ do |display_name, dependencies, git_url, tags, num_gears, metadata|
  dependencies = dependencies.split(",").map{ |dep| "  - #{dep}\n"}
  output = `rhc-admin-ctl-template -c add -n "#{display_name}" -d "Requires: \n#{dependencies}\nSubscribes:\n  doc-root:\n    Type: \"FILESYSTEM:doc-root\"" -g #{git_url} -t#{tags} --cost #{num_gears} -m '#{metadata}'`
  @template_uuid = output.split(" ")[1]
end

When /^I search for the template UUID$/ do
  url = @base_url + "/application_template/#{@template_uuid}"
  print url
  @request = RestClient::Request.new(:method => :get, :url => url, 
    :user => @username, :password => @password, :headers => @headers)
  begin
    @response = @request.execute()
  rescue => e
    @response = e.response
  end
end

When /^I search for the tag '([^\']*)'$/ do |tag|
  url = @base_url + "/application_template/#{tag}"
  @request = RestClient::Request.new(:method => :get, :url => url, 
    :user => @username, :password => @password, :headers => @headers)
  begin
    @response = @request.execute()
  rescue => e
    @response = e.response
  end
end

When /^I remove the template$/ do
  output = `rhc-admin-ctl-template -c remove -u "#{@template_uuid}"`
end

Then /^the template exists$/ do
  if @accept_type.upcase == "XML"
    page = Nokogiri::XML(@response.body)
    uuid = page.xpath("//response/application-template/uuid")
  elsif @accept_type.upcase == "JSON"
    page = JSON.parse(@response.body)
    uuid = page["data"]["uuid"]
  end

  uuid.should_not be_nil
end

Then /^the template should( not)? exist in list$/ do |n|
  if @accept_type.upcase == "XML"
    page = Nokogiri::XML(@response.body)
    templates = page.xpath("//response/data/*[uuid = \"#{@template_uuid}\"]")
  elsif @accept_type.upcase == "JSON"
    page = JSON.parse(@response.body)
    templates = page["data"][0]["uuid"].delete_if{|elem| elem != @template_uuid}
  end
  
  if n.nil?
    templates.should_not be_empty
  else
    templates.should be_empty    
  end
end

When /^I create a new application named '([^\']*)' with the template$/ do |app|
  payload = {"name" => app, "template" => @template_uuid}
  url = @base_url + "/domains/cucumber/applications"
  @request = RestClient::Request.new(:method => :post, :url => url, 
  :user => @username, :password => @password, :headers => @headers,
  :payload => payload)
  begin
    @response = @request.execute()
  rescue => e
    @response = e.response
  end
end