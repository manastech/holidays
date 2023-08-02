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
  
  # An instance of this class would represent the result of parsing a holiday definition file. It contains holiday rules, tests, metadata, 
  # and custom methods.
  class Definition
    attr_accessor :metadata
    attr_accessor :month_rules
    attr_accessor :custom_methods
    attr_accessor :tests

    def initialize(metadata, month_rules, custom_methods, tests)
      @metadata = metadata
      @month_rules = month_rules
      @custom_methods = custom_methods
      @tests = tests
    end 

    def self.from_yaml(definition)
      custom_methods = {}
      definition["methods"].each do |name, method_props|
        cm = Holidays::CustomMethod.from_yaml(name, method_props)
        custom_methods[cm.method_key] = cm
      end

      metadata = Metadata.from_yaml(definition["metadata"])

      rules_by_month = {}
      definition["months"].each do |month, rule_definitions|
        rules_by_month[month] = rule_definitions.map { |rule| Holidays::HolidayRule.from_yaml(rule, custom_methods) }
      end

      tests = definition["tests"].map { |t| Holidays::Test.from_yaml(t) }   

      Holidays::Definition.new(metadata, rules_by_month, custom_methods, tests)
    end

    def region
      metadata.region
    end
  end
end
