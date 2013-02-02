module OpenShift
  class DataStore

    def self.db(read_preference=:secondary, session_name='default')
      config = Mongoid::Config.sessions[session_name]
      host_port = config['hosts'].map { |host| host.split(':')}
      con = Mongo::ReplSetConnection.new(*host_port << {:read => read_preference})
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