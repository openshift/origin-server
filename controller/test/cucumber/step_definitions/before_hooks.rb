# Reuse or create postgres applications
Before('@postgres','~@smoke_test','~@scaled') do
  if $postgres_app
    @app = $postgres_app
  else
    step "a new client created mock-0.1 application"
    step "the embedded postgresql-8.4 cartridge is added"
    $postgres_app = @app
  end
end

# Reuse or create scaled postgres applications
Before('@postgres','~@smoke_test','@scaled') do
  if $scaled_postgres_app
    @app = $scaled_postgres_app
  else
    step 'a new client created scalable mock-0.1 application'
    step 'the minimum scaling parameter is set to 2'
    step 'the embedded postgresql-8.4 cartridge is added'
    $scaled_postgres_app = @app
  end
end

# Make sure scaled applications use the host to connect
Before('@postgres','@snapshot','@scaled','~@smoke_test') do
  step 'I use host to connect to the postgresql database as env with password'
end

# Prepare the test data once for snapshot tests
Before('@postgres','@snapshot','~@smoke_test') do
  step 'I drop existing test data'
  step 'I create a test database in postgres'
  step 'I create a test table in postgres'
  step 'I insert test data into postgres'
  step 'the test data will be present in postgres'
  step 'I snapshot the application'
  step 'I insert additional test data into postgres'
  step 'the additional test data will be present in postgres'
end

# Clear the stashed application if a scenario fails
After('@postgres','~@scaled') do |s|
  if s.failed?
    $postgres_app = nil
  end
end

# Clear the stashed application if a scenario fails
After('@postgres','@scaled') do |s|
  if s.failed?
    $scaled_postgres_app = nil
  end
end
