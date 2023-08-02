require 'yaml'
require 'holidays/definition/custom_method.rb'
require 'holidays/definition/test.rb'
require 'holidays/definition/generator.rb'

module Holidays
  class << self
    def parse_definition_files(files)
      raise ArgumentError, "Must have at least one file to parse" if files.nil? || files.empty?

      files.flatten!
      files.map do |file|
        definition_file = YAML.load_file(file)

        Holidays::Definition.from_yaml(file)
      end
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

