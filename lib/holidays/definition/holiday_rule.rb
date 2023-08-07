module Holidays
  class HolidayRule
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

    def to_source
      string = '{'
      if mday
        string << ":mday => #{mday}, "
      end

      if function
        string << ":function => \"#{function.to_s}\", "

        if function_modifier
          string << ":function_modifier => #{function_modifier.to_s}, "
        end
      end

      # This is the 'else'. It is possible for mday AND function
      # to be set but this is the fallback. This whole area
      # needs to be reworked!
      if string == '{'
        string << ":wday => #{wday}, :week => #{week}, "
      end

      if year_ranges && year_ranges.is_a?(Hash)
        selector = year_ranges.keys.first
        value = year_ranges[selector]

        string << ":year_ranges => { :#{selector} => #{value} },"
      end

      if observed
        string << ":observed => \"#{observed.to_s}\", "
      end

      if type
        string << ":type => :#{type}, "
      end

      # shouldn't allow the same region twice
      string << ":name => \"#{name}\", :regions => [:" + regions.uniq.join(', :') + "]}"
    end

    def informal?
      type == :informal || type == 'informal'
    end

    # Compares two `HolidayRule`s for equality on every property _except_ the defined regions.
    # We want to be able to easily tell if the same holiday is defined for multiple regions.
    def ==(other)
      other.name == name \
        and other.wday == wday \
        and other.mday == mday \
        and other.week == week \
        and other.type == type \
        and other.function == function \
        and other.function_modifier == function_modifier \
        and other.observed == observed \
        and other.year_ranges == year_ranges
    end
  end
end
