require 'yaml'
require 'holidays/definition/custom_method.rb'
require 'holidays/definition/test.rb'
require 'holidays/definition/region_definition.rb'
require 'holidays/definition/region_module.rb'

module Holidays::Generator
  # The "ca", "mx", and "us" holiday definitions include the "northamericainformal"
  # holiday definitions, but that does not make these countries subregions of one another.
  NORTH_AMERICA_REGIONS = %i[ca mx us].freeze

  class << self
    # Given a list of filenames, perform the following operations:
    # 1. Load the file contents as YAML
    # 2. Create an instance of `RegionDefinition` based on the parsed YAML.
    # This will return a list of `RegionDefinition`s, one for each file passed in.
    def parse_definition_files(files)
      raise ArgumentError, "Must have at least one file to parse" if files.nil? || files.empty?

      files.flatten!
      files.map do |file|
        begin
          definition_file = YAML.load_file(file)

          Holidays::RegionDefinition.from_yaml(definition_file)
        rescue ArgumentError => error
          raise ArgumentError.new("Failed to parse #{file}: #{error.message}")
        end
      end
    end

    # Generate module source code and test source code for a `RegionModule`. The module source code is particularly
    # important because that will be what the gem will load at runtime in order to perform holiday lookups.
    def generate_definition_source(region_module)
      module_source = region_module.to_module_source
      test_source = region_module.to_test_source

      return module_source, test_source || ''
    end

    # Generate region lookup information based on all of the available region modules. This should only be called after
    # all of the available holiday definition files have been parsed and loaded into `RegionModule`s.
    def generate_regions(region_modules)
      region_array = region_modules.flat_map(&:regions).uniq

      metadata_by_region = {}
      region_modules.each do |region_module|
        metadata_by_region.merge! region_module.metadata_by_region
      end

      <<-EOF
# encoding: utf-8
module Holidays
  REGIONS = #{region_array}

  PARENT_REGION_LOOKUP = #{generate_parent_region_lookup(region_modules)}

  REGION_METADATA_LOOKUP = #{metadata_by_region}
  end
EOF
    end

    private

    def generate_parent_region_lookup(region_modules)
      lookup = {}

      region_modules.each do |region_module|
        top_level_region = region_module.name.to_sym
        region_module.regions.each do |subregion|
          parent_region = NORTH_AMERICA_REGIONS.include?(subregion) ? subregion : top_level_region
          lookup[subregion] = parent_region unless lookup.has_key?(subregion)
        end
      end

      lookup
    end
  end 
end

