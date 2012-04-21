require "stickshift-common"
require "crankcase-mongo-plugin/crankcase/mongo_data_store.rb"
StickShift::DataStore.provider=Crankcase::MongoDataStore
