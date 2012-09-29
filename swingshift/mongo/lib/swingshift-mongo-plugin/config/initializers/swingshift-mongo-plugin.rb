Broker::Application.configure do
    # Replica set example: [[<host-1>, <port-1>], [<host-2>, <port-2>], ...]
    config.auth[:mongo_replica_sets] = false
    config.auth[:mongo_host_port] = ["localhost", 27017]

    config.auth[:mongo_user] = "stickshift"
    config.auth[:mongo_password] = "mooo"
    config.auth[:mongo_db] = "stickshift_broker_dev"
    config.auth[:mongo_collection] = "auth_user"
end
