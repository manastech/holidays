require 'yaml'
require 'holidays/definition/custom_method.rb'
require 'holidays/definition/test.rb'
require 'holidays/definition/region_definition.rb'

module Holidays::Parser
  class << self
    # Load a region definition file into a `RegionDefinition` instance.
    def parse_definition_file(file)
      definition_file = YAML.load_file(file)
      region_definition = Holidays::RegionDefinition.from_yaml(definition_file)
      region_definition.metadata[:filename] = file

      region_definition
    rescue ArgumentError => error
      raise ArgumentError.new("Failed to parse #{file}: #{error.message}")
    end
  end 
end

