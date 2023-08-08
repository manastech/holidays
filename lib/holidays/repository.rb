
module Holidays
  # This class holds all of the holiday definitions, custom methods, and region info that have been loaded
  # into the "runtime" of the library. When holidays are being queried, the data will come from this
  # class.
  class Repository
    attr_reader :regions
    attr_reader :region_metadata
    attr_accessor :custom_methods
    
    def initialize
      @holidays_by_month = {}
      @custom_methods = {}
      @regions = []
      @region_metadata = {}
    end

    def add_region_definition(definition)
      return if @regions.include?(definition.region)

      @regions << definition.region
      @region_metadata[definition.region] = definition.metadata

      definition.month_rules.each do |month, rules|
        @holidays_by_month[month] = [] unless @holidays_by_month[month]

        rules.each do |rule|
          exists = false
          @holidays_by_month[month].each do |holiday|
            if holiday == rule
              holiday.add_region definition.region
              exists = true
            end
          end

          @holidays_by_month[month] << rule unless exists
        end
      end

      @custom_methods.merge! definition.custom_methods
    end

    def get_holidays_for_month(month)
      @holidays_by_month[month]
    end

    # Returns an array of regions. If `region` is a "concrete" region name (i.e., not a wildcard) and the region
    # exists in the `regions` array, then `region` will be returned as a single-item array. If `region` is a 
    # wildcard, then all matching regions will be returned in an array. If `region` is a concrete name or wildcard
    # with no corresponding item in `regions`, then an empty array will be returned.
    def lookup_region(region)
      return [] if region.nil?

      if region.to_s.ends_with?('_')
        parent_region = region.to_s.split('_').first
        return regions.select { |r| r.to_s.start_with?(parent_region) }
      elsif regions.include?(region)
        return [region]
      else 
        return []
      end
    end

    # Return `true` if the input region has been loaded. If the input region is a wildcard (ends with '_'),
    # then any child region will count.
    def includes_region?(region)
      if region.to_s.ends_with?('_')
        parent_region = region.to_s.split('_').first
        # The region is a wildcard, which means we should return true if any subregion is present
        @regions.any? { |r| r.to_s.start_with?(parent_region) }
      else
        # This region is not a wildcard, so we just do an exact match
        @regions.include?(region)
      end
    end
  end
end
