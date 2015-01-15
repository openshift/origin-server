module OpenShift
  class DataStore
    def self.db(read_preference=:secondary_preferred, session_name='default')
      config = Mongoid::Config.sessions[session_name]
      hosts = config['hosts']
      ssl = config['options']['ssl']
      if hosts.length > 1
        con = defined?(MongoReplicaSetClient) \
          ? MongoReplicaSetClient.new(hosts, :read => read_preference, :ssl => ssl)
          # compatibility with mongo 1.6 API
          : Mongo::ReplSetConnection.new(hosts, :read => read_preference, :ssl => ssl)
      else
        host_port = hosts[0].split(':')
        con = defined?(MongoClient) ? MongoClient.new(host_port[0], host_port[1].to_i, :ssl => ssl)
                                    # compatibility with mongo 1.6 API
                                    : Mongo::Connection.new(host_port[0], host_port[1].to_i, :ssl => ssl)
      end
      db = con.db(config['database'])
      db.authenticate(config['username'], config['password'])
      db
    end

    def self.find(collection_name, query, selection)
      db_handle = db
      db_handle.collection(collection_name).find(query, selection) do |mcursor|
        mcursor.each do |hash|
          yield hash
        end
      end
      db_handle.connection.close if db_handle and db_handle.connection and db_handle.connection.connected?
    end

  end
end
