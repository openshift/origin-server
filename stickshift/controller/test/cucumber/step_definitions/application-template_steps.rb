require 'timeout'

Given /^there are no templates$/ do
  `mongo openshift_broker_dev --eval "db.template.drop()"`
end

When /^I add a new template named '([^\']*)' with dependencies: '([^\']*)' and git repository '([^\']*)' and tags '([^\']*)' consuming (\d+) gear and metadata '([^\']*)'$/ do |display_name, dependencies, git_url, tags, num_gears, metadata|
  dependencies = dependencies.split(",").map{ |dep| "  - #{dep}\n"}
  output = `rhc-admin-ctl-template -c add -n "#{display_name}" -d "Requires: \n#{dependencies}\nSubscribes:\n  doc-root:\n    Type: \"FILESYSTEM:doc-root\"" -g #{git_url} -t#{tags} --cost #{num_gears} -m '#{metadata}'`
  @template_uuid = output.split(" ")[1]
end

When /^I add a new rails template$/ do
  descriptor_yaml = "---\nDisplay-Name: rails-0.0-noarch\nArchitecture: noarch\nName: rails\nLicense: unknown\nDescription: ""\nConnections:\n  mysql-5.1-ruby-1.8:\n    Components:\n    - ruby-1.8\n    - mysql-5.1\nRequires:\n- ruby-1.8\n- mysql-5.1\nSubscribes:\n  doc-root:
\n    Required: false\n    Type: FILESYSTEM:doc-root\nVendor: unknown\nVersion: \"0.0\"\n"
  metadata_json = '{ "license": "mit", "version": "3.1.1", "git": "https://github.com/openshift/rails-example", "description": "An open-source web framework that is optimized for programmer happiness and sustainable productivity. It lets you write beautiful code by favoring convention over configuration\n", "website": "http://rubyonrails.org/" }'

  File.open( "/tmp/descriptor.yaml", "w" ) { |f| f.write(descriptor_yaml) }
  File.open( "/tmp/metadata.json", "w" ) { |f| f.write(metadata_json) }

  output = `rhc-admin-ctl-template --named 'Ruby on Rails' --metadata '/tmp/metadata.json' --git-url 'https://github.com/openshift/rails-example' --command 'add' --cost '1' --descriptor '/tmp/descriptor.yaml' --tags 'ruby,rails,framework'`
  @template_uuid = output.split(" ")[1]
end

Then /^the application should be accessable$/ do
  retry_times = 0
  begin
    url = URI.parse(@app_url)
    request = Net::HTTP::Get.new( "/" + url.path)
    response = Net::HTTP.start(url.host, url.port) { |http|
      http.request(request)
    }

    if response.code != "200"
      print "Response was #{response.code}\n"
      raise "Response was not 200, response was #{response.code}"
    end
  rescue Exception => e
    print "Response was #{e.message}\n"
    retry_times = retry_times + 1
    raise if retry_times > 100
    sleep 15
    print "Sleeping 15 seconds...\n"
    retry
  end
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

When /^I create a new application named '([^\']*)' within domain '([^\']*)' with the template$/ do |app, domain|
  domain = sub_random(domain)
  payload = {"name" => app, "template" => @template_uuid}
  url = @base_url + "/domains/#{domain}/applications"
  @app_url = "http://#{app}-#{domain}.dev.rhcloud.com"
  print "Post to #{url} values #{payload.to_json} User #{@username}\n"
  @request = RestClient::Request.new(:method => :post, :url => url, 
  :user => @username, :password => @password, :headers => @headers,
  :payload => payload)
  begin
    @response = @request.execute()
  rescue => e
    @response = e.response
  end
end
