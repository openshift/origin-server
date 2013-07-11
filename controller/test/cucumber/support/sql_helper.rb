module SQLHelper
  # Create a string of exports from the env variables
  #  - Any vars passed with an empty string are set to the empty string
  #  - Any vars passed as nil are removed from clean_vars
  def env_vars_string(clear_vars, keep_vars = {})
    vars = clear_vars.inject({}){ |hash,val| hash[val] = ''; hash }
    vars.merge!(keep_vars)
    vars.delete_if{|_,v| v.nil? }
    vars.inject(""){|str,(key,val)| "#{str} export #{key}=#{val};"}.strip
  end

  def run_psql(statement)
    @psql_env ||= {}
    @psql_opts ||= {}
    # If we don't specify any options, assume we want the helper
    @psql_helper = @psql_env.empty? && @psql_opts.empty?

    # Default options
    default_opts = {
      '-t' => '', # only output tuples from queries
      '-w' => '', # never prompt for password
      '-d' => '$OPENSHIFT_APP_NAME' # always use proper db name
    }

    cmd = 'psql'

    # SCP the file so we don't have to worry about escaping SQL
    if @app.respond_to?(:scp_content)
      default_opts['-f'] = @app.scp_content(statement)
    else
      cmd = "echo '#{statement}' | #{cmd}"
    end

    # If we don't pass anything, assume we want the normal user environment
    unless @psql_helper
      # These vars will be set to an empty string unless overridden
      clear_vars = %w(PGPASSFILE PGUSER PGHOST PGDATABASE PGDATA PGPASSWORD)
      # Prepend the export statements to the command
      cmd = "%s #{cmd}" % env_vars_string(clear_vars, @psql_env)
    end

    # Add out default opts
    opts = default_opts.merge(@psql_opts)
    # Remove any nil opts (but leave empty string)
    opts.delete_if{|k,v| v.nil? }
    # Turn opts into '-k val' format
    opts = opts.inject(""){|str,(key,val)| "#{str} #{key} #{val}" }.strip

    cmd = "\"#{cmd} #{opts}\""
    cmd.gsub!(/\$/,'\\$')

    output = if @app && @app.respond_to?(:ssh_command)
               @app.ssh_command(cmd)
             else
               cmd = ssh_command(cmd)
               $logger.debug "Running #{cmd}"

               output = `#{cmd}`

               $logger.debug "Output: #{output}"
               output
             end
    @exitstatus = $?.exitstatus
    return output.strip
  end
end

World(SQLHelper)
