module AdminConsole
  Bin = Struct.new(:bin, :count) do
    def self.from_mongo_aggregate(bson)
      new(bson["_id"], bson["count"])
    end
  end
end