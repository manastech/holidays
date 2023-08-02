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
    attr_accessor :function_arguments
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
      @function_arguments = rule[:function_arguments]
      @regions = rule[:regions]
      @function_modifier = rule[:function_modifier]
    end

    def self.from_yaml(rule_definition, parsed_custom_methods)
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

      if rule[:function]
        rule[:function_arguments] = get_function_arguments(rule[:function], parsed_custom_methods)
      end

      HolidayRule.new(rule)
    end

    def to_source(parsed_custom_methods)
      string = '{'
      if mday
        string << ":mday => #{mday}, "
      end

      if function
        string << ":function => \"#{function.to_s}\", "

        # We need to add in the arguments so we can know what to send in when calling the custom proc during holiday lookups.
        # NOTE: the allowed arguments are enforced in the custom methods parser.
        string << ":function_arguments => #{HolidayRule.get_function_arguments(function, parsed_custom_methods)}, "

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
        string << ":observed_arguments => #{HolidayRule.get_function_arguments(observed, parsed_custom_methods)}, "
      end

      if type
        string << ":type => :#{type}, "
      end

      # shouldn't allow the same region twice
      string << ":name => \"#{name}\", :regions => [:" + regions.uniq.join(', :') + "]}"
    end

    def ==(other)
      other.name == name \
        and other.wday == wday \
        and other.mday == mday \
        and other.week == week \
        and other.type == type \
        and other.function == function \
        and other.observed == observed \
        and other.year_ranges == year_ranges
    end

    private

    # This method sucks. The issue here is that the custom methods repo has the 'general' methods (like easter)
    # but the 'parsed_custom_methods' have the recently parsed stuff. We don't load those until they are needed later.
    # This entire file is a refactor target so I am adding some tech debt to get me over the hump.
    # What we should do is ensure that all custom methods are loaded into the repo as soon as they are parsed
    # so we only have one place to look.
    def self.get_function_arguments(function_id, parsed_custom_methods)
      if method = Holidays::Factory::Definition.custom_methods_repository.find(function_id)
        method.parameters.collect { |arg| arg[1] }
      elsif method = parsed_custom_methods[function_id]
        method.arguments.collect { |arg| arg.to_sym }
      end
    end
  end
end
