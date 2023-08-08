module Holidays
  class Metadata
    def initialize(input)
      @data = input.transform_keys { |key| key.to_sym }
      @data[:region] = @data[:region].to_sym
    end

    # Load metadata from the definition YAML file. `name` and `region` are required parameters. This also checks for a
    # `description` which can be used to give a little extra context to a calendar, but it can be nil.
    def self.from_yaml(metadata_def)
      raise ArgumentError, "Expected name to be defined in metadata block" unless metadata_def['name']
      raise ArgumentError, "Expected region to be defined in metadata block" unless metadata_def['region']

      Metadata.new(metadata_def)
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      @data[key] = value
    end

    def name
      @data[:name]
    end

    def region
      @data[:region]
    end

    def description
      @data[:description]
    end

    def to_h
      @data
    end
  end
end

