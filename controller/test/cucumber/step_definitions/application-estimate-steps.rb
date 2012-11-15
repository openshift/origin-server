When /^I provide application descriptor with name '([^\']*)' and dependencies:'([^\']*)' and groups:'([^\']*)'$/ do |app_name, dependencies, groups|
  requires = "Requires:\n"
  dependencies.split(",").each do |dep|
    requires += "  - #{dep}\n"
  end
  if !groups.empty?
    groups = groups.split(";").map{ |grp| " - [#{grp}]"}
    groups = groups.join("\n")
  end
  descriptor = "--- \nName: #{app_name}\n#{requires}"
  descriptor += "GroupOverrides: \n#{groups}\n" if !groups.empty?

  payload = {"descriptor" => descriptor}
  url = @base_url + "/estimates/application"
  @request = RestClient::Request.new(:method => :get, :url => url,
    :user => @username, :password => @password, :headers => @headers,
    :payload => payload)
  
  begin
    @response = @request.execute()
  rescue => e
    @response = e.response
  end
end

Then /^should get (\d) gears$/ do |num_gears|
  page = JSON.parse(@response.body)
  @gears = page["data"]
  @gears.size.should be == num_gears.to_i
end

Then /^should get (\d) gear with '([^\']*)' component(s)?$/ do |num_gears, components, skip|
  components = components.split(',')
  matched_gears = 0

  @gears.each do |g|
    comps = []
    g["components"].each do |comp|
      comps.push comp['Name']
    end

    match = 0
    components.each do |c|
      break if !comps.include?(c)
      match += 1
    end
    matched_gears += 1 if match == components.size
  end if @gears

  matched_gears.should be == num_gears.to_i
end
