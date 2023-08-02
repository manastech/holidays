module Holidays
  class Metadata
    attr_reader :name
    attr_reader :region
    
    def initialize(name, region)
      @name = name
      @region = region
    end

    def self.from_yaml(metadata_def)
      raise ArgumentError, "Expected region to be defined in metadata block" unless metadata_def["region"]

      Metadata.new(
        metadata_def['name'],
        metadata_def['region'].to_sym
      )
    end

    def to_h
      { name: name, region: region }
    end
  end
end

