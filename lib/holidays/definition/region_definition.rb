require "holidays/definition/holiday_rule.rb"
require "holidays/definition/custom_method.rb"
require "holidays/definition/test.rb"

module Holidays
  Metadata = Struct.new(:name, :region) do
    def self.from_yaml(metadata_def)
      raise ArgumentError, "Expected region to be defined in metadata block" unless metadata_def["region"]

      Metadata.new({
        name: metadata_def['name'],
        region: metadata_def['region'].to_sym
      })
    end
  end
  
  # An instance of this class would represent the result of parsing a holiday definition file. Each holiday definition file contains holiday rules, tests, metadata, 
  # and custom methods for a single region.
  class RegionDefinition
    attr_accessor :metadata
    attr_accessor :month_rules
    attr_accessor :custom_methods
    attr_accessor :tests

    def initialize(metadata, month_rules, custom_methods, tests)
      # TODO: Right now we're adding the region to each rule individually, since the rule will need to access it in the generated source code.
      # We could either do this now, or we could do it later while we're actually generating the source code. I'm choosing to do it here
      # because it seems like more of a validation/initialization issue.
      puts "Metadata region: #{metadata.region}"
      month_rules.values.each do |rules|
        rules.each do |rule|
          if rule.regions.nil?
            rule.regions = [metadata.region]
          elsif rule.regions.empty?
            rule.regions << metadata.region
          end
        end
      end

      @metadata = metadata
      @month_rules = month_rules
      @custom_methods = custom_methods
      @tests = tests
    end 

    def self.from_yaml(definition)
      raise ArgumentError, "Definition file must provide a metadata block" if definition["metadata"].nil?
      raise ArgumentError, "Definition file must provide a months block" if definition["months"].nil?
      
      custom_methods = {}
      definition["methods"]&.each do |name, method_props|
        cm = Holidays::CustomMethod.from_yaml(name, method_props)
        custom_methods[cm.method_key] = cm
      end

      metadata = Metadata.from_yaml(definition["metadata"])

      rules_by_month = {}
      definition["months"].each do |month, rule_definitions|
        rules_by_month[month] = rule_definitions.map { |rule| Holidays::HolidayRule.from_yaml(rule, custom_methods) }
      end

      tests = definition["tests"]&.map { |t| Holidays::Test.from_yaml(t) }   

      Holidays::RegionDefinition.new(metadata, rules_by_month, custom_methods, tests)
    end

    def region
      metadata.region
    end
  end
end
