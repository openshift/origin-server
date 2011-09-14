# Configure barista.
Barista.configure do |c|

  # Change the root to use app/scripts
  # c.root = Rails.root.join("app", "scripts")

  # Change the output root, causing Barista to compile into public/coffeescripts
  # c.output_root = Rails.root.join("public", "coffeescripts")
  #
  # Disable auto compile, use generated file directly:
  # c.auto_compile = false

  # Add a new framework:

  # c.register :tests, :root => Rails.root.join('test', 'coffeescript'), :output_prefix => 'test'

  # Disable wrapping in a closure:
  # c.bare = true
  # ... or ...
  # c.bare!

  # Change the output root for a framework:

  # c.change_output_prefix! 'framework-name', 'output-prefix'

  # or for all frameworks...

  # c.each_framework do |framework|
  #   c.change_output_prefix! framework, "vendor/#{framework.name}"
  # end

  # or, prefix the path for the app files:

  # c.change_output_prefix! :default, 'my-app-name'

  # or, change the directory the framework goes into full stop:

  # c.change_output_prefix! :tests, Rails.root.join('spec', 'javascripts')

  # or, hook into the compilation:

  c.before_compilation   { |path|         puts "Barista: Compiling #{path}" }
  c.on_compilation       { |path|         puts "Barista: Successfully compiled #{path}" }
  c.on_compilation_error { |path, output| puts "Barista: Compilation of #{path} failed with:\n#{output}" }
  c.on_compilation_with_warning { |path, output| puts "Barista: Compilation of #{path} had a warning:\n#{output}" }

  # Turn off preambles and exceptions on failure:

  # c.verbose = false

  # Or, make sure it is always on
  # c.verbose!

  # If you want to use a custom JS file, you can as well
  # e.g. vendoring CoffeeScript in your application:
  # c.js_path = Rails.root.join('public', 'javascripts', 'coffee-script.js')

  # Make helpers and the HAML filter output coffee-script instead of the compiled JS.
  # Used in combination with the coffeescript_interpreter_js helper in Rails.
  # c.embedded_interpreter = true

end
