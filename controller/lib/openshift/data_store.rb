module OpenShift
  class DataStore

    def self.db(read_preference=:secondary, session_name='default')
      config = Mongoid::Config.sessions[session_name]
      hosts = config['hosts']
      if hosts.length > 1
        con = Mongo::ReplSetConnection.new(hosts, {:read => read_preference})
      else
        host_port = hosts[0].split(':')
        con = Mongo::Connection.new(host_port[0], host_port[1].to_i)
      end
      db = con.db(config['database'])
      db.authenticate(config['username'], config['password'])
      db
    end

    def self.find(collection_name, query, selection)
      db = get_database
      db.collection(collection_name).find(query, selection) do |mcursor|
        mcursor.each do |hash|
          yield hash
        end
      end
    end

  end
end