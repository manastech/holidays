module Holidays
  class HolidayRule
    alias_method :eql?, :==
    
    attr_accessor :name
    attr_accessor :wday
    attr_accessor :mday
    attr_accessor :week
    attr_accessor :type
    attr_accessor :observed
    attr_accessor :function
    attr_accessor :year_ranges
    attr_accessor :function_modifier
    attr_accessor :regions
    
    def initialize(rule)
      @name = rule[:name]
      @wday = rule[:wday]
      @mday = rule[:mday]
      @week = rule[:week]
      @type = rule[:type]
      @observed = rule[:observed]
      @function = rule[:function]
      @year_ranges = rule[:year_ranges]
      @regions = rule[:regions]
      @function_modifier = rule[:function_modifier]
    end

    def self.from_yaml(rule_definition)
      rule = {}

      rule_definition.each do |key, val|
        val.transform_keys!(&:to_sym) if val.is_a?(Hash)
        rule[key.to_sym] = val
      end

      if rule[:year_ranges] && rule[:year_ranges].key?(:between)
        start_year = rule[:year_ranges][:between]["start"].to_i
        end_year = rule[:year_ranges][:between]["end"].to_i

        rule[:year_ranges][:between] = Range.new(start_year, end_year)
      end

      HolidayRule.new(rule)
    end

    def informal?
      type == :informal || type == 'informal'
    end

    def add_region(region)
      @regions << region
      @regions.uniq!
    end

    # Compares two `HolidayRule`s for equality on every property _except_ the defined regions.
    # We want to be able to easily tell if the same holiday is defined for multiple regions.
    def ==(other)
      other.class == self.class && other.state == state
    end

    def hash
      state.hash
    end

    protected

    def state
      [@name, @wday, @mday, @week, @type, @function, @function_modifier, @observed, @year_ranges]
    end
  end
end
