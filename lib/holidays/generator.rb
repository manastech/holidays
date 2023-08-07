require 'yaml'
require 'holidays/definition/custom_method.rb'
require 'holidays/definition/test.rb'
require 'holidays/definition/region_definition.rb'

module Holidays::Parser
  class << self
    # Given a list of filenames, perform the following operations:
    # 1. Load the file contents as YAML
    # 2. Create an instance of `RegionDefinition` based on the parsed YAML.
    # This will return a list of `RegionDefinition`s, one for each file passed in.
    def parse_definition_files(files)
      raise ArgumentError, "Must have at least one file to parse" if files.nil? || files.empty?

      files.flatten!
      files.map { |file| parse_definition_file(file) }
    end

    def parse_definition_file(file)
      definition_file = YAML.load_file(file)
      Holidays::RegionDefinition.from_yaml(definition_file)
    rescue ArgumentError => error
      raise ArgumentError.new("Failed to parse #{file}: #{error.message}")
    end
  end 
end

