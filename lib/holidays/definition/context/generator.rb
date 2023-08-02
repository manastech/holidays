require 'yaml'
require 'holidays/definition/custom_method.rb'
require 'holidays/definition/test.rb'
require 'holidays/definition/generator.rb'

module Holidays
  class << self
    def parse_definition_files(files)
      raise ArgumentError, "Must have at least one file to parse" if files.nil? || files.empty?

      all_regions = []
      all_rules_by_month = {}
      all_custom_methods = {}
      all_metadata_by_region = {}
      all_tests = []

      files.flatten!

      files.each do |file|
        definition_file = YAML.load_file(file)

        custom_methods = {}
        definition_file["methods"].each do |name, method_props|
          cm = Holidays::CustomMethod.from_yaml(name, method_props)
          custom_methods[cm.method_key] = cm
        end

        rules_by_month = parse_month_definitions(definition_file['months'], custom_methods)

        if definition_file['metadata']
          metadata_region, metadata = parse_metadata_definitions(definition_file['metadata'])
          metadata_region_sym = metadata_region.to_sym if metadata_region
          if metadata_region_sym and !all_metadata_by_region.key?(metadata_region_sym)
            all_metadata_by_region[metadata_region_sym] = metadata
          end

          all_regions << metadata_region_sym 

          rules_by_month.each do |month, rules|
            rules.each do |rule|
              rule[:regions] = [metadata_region_sym]
            end
          end
        end

        all_rules_by_month.merge!(rules_by_month) { |month, existing, new|
          existing << new
          existing.flatten!
        }

        # FIXME This is a problem. We will have a 'global' list of methods. That's always bad. What effects will this have?
        # This is an existing problem (just so we are clear). An issue would be extremely rare because we are generally parsing
        # single files/custom files. But it IS possible that we would parse a bunch of things at the same time and step
        # on each other so we need a solution.
        all_custom_methods.merge!(custom_methods)

        definition_file["tests"].each do |t|
          all_tests += Holidays::Test.from_yaml(t)
        end
      end

      all_regions.uniq!

      [all_regions, all_rules_by_month, all_metadata_by_region, all_custom_methods, all_tests]
    end

    def generate_definition_source(module_name, files, regions, rules_by_month, custom_methods, tests)
      month_strings = generate_month_definition_strings(rules_by_month, custom_methods)

      # Build the custom methods string
      custom_method_string = ''
      custom_methods.each do |key, code|
        custom_method_string << code.to_source + ",\n\n"
      end

      module_src = Holidays::Definition::Generator.generate_module_source(module_name, files, regions, month_strings, custom_method_string)
      test_src = Holidays::Definition::Generator.generate_test_source(module_name, files, tests)

      return module_src, test_src || ''
    end

    private

    def parse_metadata_definitions(metadata_definitions)
      metadata_definitions.transform_keys!(&:to_sym) if metadata_definitions.is_a?(Hash)

      if metadata_definitions[:region]
        metadata_region = metadata_definitions[:region].to_sym if metadata_definitions[:region]
        metadata_definitions.delete(:region)
      end
    
      [metadata_region, metadata_definitions]
    end

    def parse_month_definitions(month_definitions, parsed_custom_methods)
      return {} unless month_definitions
      rules_by_month = {}

      month_definitions.each do |month, definitions|
        rules_by_month[month] = [] unless rules_by_month[month]
        definitions.each do |definition|
          rule = Holidays::HolidayRule.from_yaml(definition, parsed_custom_methods)

          exists = false
          rules_by_month[month].each do |ex|
            if ex == rule
              ex.regions << rule.regions.flatten
              exists = true
            end
          end

          unless exists
            rules_by_month[month] << rule
          end
        end
      end

      rules_by_month
    end

    #FIXME This should really be split out and tested with its own unit tests.
    def generate_month_definition_strings(rules_by_month, parsed_custom_methods)
      month_strings = []

      rules_by_month.each do |month, rules|
        rule_string = rules.map { |rule| rule.to_source(parsed_custom_methods) }.join(",\n            ")
        month_strings <<  "      #{month.to_s} => [#{rule_string}]"
      end

      return month_strings
    end

  end 
end

