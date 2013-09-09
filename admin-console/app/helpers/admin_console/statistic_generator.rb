module AdminConsole
  module StatisticGenerator
    extend ActiveSupport::Concern

    module ClassMethods
      def binning_from_mongo_aggregate(mongo_response, bin_size = 1, bin_max = 100)
        bins_map = {}
        final_bins = []
        mongo_response.each do |mongo_bin| 
          bins_map[mongo_bin["_id"]] = mongo_bin
        end
        $i = 0
        while $i < bin_max do
          if (bins_map[$i])
            final_bins << Bin.from_mongo_aggregate(bins_map[$i])
          else
            final_bins << Bin.new($i, 0)
          end
          $i += bin_size
        end
        {:bins => final_bins}
      end
    end
  end
end