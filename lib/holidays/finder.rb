require 'holidays/finder/dates_driver_builder'

module Holidays::Finder
  class << self
    def between(start_date, end_date, options)
      raise ArgumentError unless start_date
      raise ArgumentError unless end_date

      regions, opts = parse_options(options)
      dates_driver = Holidays::Finder.dates_driver_builder(start_date, end_date)

      search(dates_driver, regions, opts)
        .select { |holiday| holiday[:date].between?(start_date, end_date) }
        .sort_by { |a| a[:date] }
    end

    def next_holiday(holidays_count, from_date, options)
      raise ArgumentError unless holidays_count
      raise ArgumentError if holidays_count <= 0
      raise ArgumentError unless from_date

      regions, opts = parse_options(options)

      holidays = []

      # This could be smarter but I don't have any evidence that just checking for
      # the next 12 months will cause us issues. If it does we can implement something
      # smarter here to check in smaller increments.
      dates_driver = Holidays::Finder.dates_driver_builder(from_date, from_date >> 12)

      search(dates_driver, regions, opts)
        .sort_by { |a| a[:date] }
        .each do |holiday|
          if holiday[:date] >= from_date
            holidays << holiday
            holidays_count -= 1
            break if holidays_count == 0
          end
        end

      holidays.sort_by { |a| a[:date] }
    end
        
    def year_holiday(from_date, options)
      raise ArgumentError unless from_date && from_date.is_a?(Date)

      regions, opts = parse_options(options)

      # This could be smarter but I don't have any evidence that just checking for
      # the next 12 months will cause us issues. If it does we can implement something
      # smarter here to check in smaller increments.
      #
      #FIXME Could this be until the to_date instead? Save us some processing?
      #      This is matching what was in holidays.rb currently so I'm keeping it. -pp
      dates_driver = Holidays::Finder.dates_driver_builder(from_date, from_date >> 12)

      to_date = Date.civil(from_date.year, 12, 31)
      holidays = []

      search(dates_driver, regions, opts).each do |holiday|
        if holiday[:date] >= from_date && holiday[:date] <= to_date
          holidays << holiday
        end
      end

      holidays.sort_by { |a| a[:date] }
    end

    private

    def search(dates_driver, regions, options)
      informal_is_set = options&.include?(:informal) || false
      observed_is_set = options&.include?(:observed) || false

      puts "Getting holidays for #{regions}"

      holidays = []
      dates_driver.each do |year, months|
        months.each do |month|
          next unless hbm = Holidays.repository.get_holidays_for_month(month)

          hbm.each do |h|

            next if h.informal? && !informal_is_set
            next unless holiday_in_region(regions, h.regions)

            if h.year_ranges
              next unless holiday_in_year_range(year, h.year_ranges)
            end

            date = build_date(year, month, h)
            next unless date

            if observed_is_set && h.observed
              date = build_observed_date(date, regions, h)
            end

            holidays << {:date => date, :name => h.name, :regions => h.regions}
          end
        end
      end

      holidays
    end
    
    def holiday_in_region(requested, available)
      return true if requested.include?(:any)

      available.any? do |a| 
        requested.any? { |r| r.to_s.start_with?(a.to_s) }
      end
    end
    
    def holiday_in_year_range(target_year, year_range_defs)
      raise ArgumentError.new("target_year must be a number") unless target_year.is_a?(Integer)
      raise ArgumentError.new("year_range_defs cannot be missing") if year_range_defs.nil? || year_range_defs.empty?
      raise ArgumentError.new("year_range_defs must contain a hash with a single operator") unless year_range_defs.is_a?(Hash) && year_range_defs.size == 1

      operator = year_range_defs.keys.first
      value = year_range_defs[operator]

      raise ArgumentError.new("Invalid operator found: '#{operator}'") unless [:until, :from, :limited, :between].include?(operator)

      operator = year_range_defs.keys.first
      rule_value = year_range_defs[operator]

      case operator
      when :until
        raise ArgumentError.new("until operator value must be a number, received: '#{value}'") unless value.is_a?(Integer)
        matched = target_year <= rule_value
      when :from
        raise ArgumentError.new("from operator value must be a number, received: '#{value}'") unless value.is_a?(Integer)
        matched = target_year >= rule_value
      when :limited
        raise ArgumentError.new("limited operator value must be an array containing at least one integer value, received: '#{value}'") unless value.is_a?(Array) && value.size >= 1 && value.all? { |v| v.is_a?(Integer) }
        matched = rule_value.include?(target_year)
      when :between
        raise ArgumentError.new(":between operator value must be a range, received: '#{value}'") unless value.is_a?(Range)
        matched = rule_value.cover?(target_year)
      else
        matched = false
      end

      matched
    end

    def build_date(year, month, h)
      if h.function
        holiday = custom_holiday(year, month, h)
        #FIXME The result should always be present, see https://github.com/holidays/holidays/issues/204 for more information
        current_month = holiday&.month
        current_day = holiday&.mday
      else
        current_month = month
        current_day = h.mday || Holidays::DateCalculator.day_of_month(year, month, h.week, h.wday)
      end

      # Silently skip bad mdays
      #TODO Should we be doing something different here? We have no concept of logging right now. Maybe we should add it?
      Date.civil(year, current_month, current_day) rescue nil
    end

    def custom_holiday(year, month, h)
      process_function(
        build_custom_method_input(year, month, h.mday, h.regions),
        h.function, h.function_modifier,
      )
    end

    def build_observed_date(date, regions, h)
      process_function(
        build_custom_method_input(date.year, date.month, date.day, regions),
        h.observed,
      )
    end

    def build_custom_method_input(year, month, day, regions)
      {
        year: year,
        month: month,
        day: day,
        region: regions.first, #FIXME This isn't ideal but will work for our current use case...
      }
    end

    def process_function(input, func_id, func_modifier = nil)
      raise ArgumentError if input.nil? || input.empty?

      input.each_key do |name|
        raise ArgumentError unless Holidays::CustomMethod::VALID_ARGUMENTS.include?(name)
      end

      raise ArgumentError if input[:year] && !input[:year].is_a?(Integer)
      raise ArgumentError if input[:month] && (input[:month] < 0 || input[:month] > 12)
      raise ArgumentError if input[:day] && (input[:day] < 1 || input[:day] > 31)
      raise ArgumentError if input[:region] && !input[:region].is_a?(Symbol)

      function = Holidays.repository.custom_methods[func_id]
      raise Holidays::FunctionNotFound.new("Unable to find function with id '#{func_id}'") if function.nil?

      result = function.call(input)
      if result.kind_of?(Date)
        # NOTE: This could be a positive OR negative number.
        result += func_modifier if func_modifier
      elsif result.is_a?(Integer)
        begin
          result = Date.civil(input[:year], input[:month], result)
        rescue ArgumentError
          raise Holidays::InvalidFunctionResponse.new("invalid day response from custom method call resulting in invalid date. Result: '#{result}'")
        end
      elsif result.nil?
        # Do nothing. This is because some functions can return 'nil' today.
        # I want to change this and so rather than come up with a clean
        # implementation I'll do this so we don't throw an error in this specific
        # situation. This should be removed once we have changed the existing
        # custom definition functions. See https://github.com/holidays/holidays/issues/204
      else
        raise Holidays::InvalidFunctionResponse.new("invalid response from custom method call, must be a 'date' or 'integer' representing the day. Result: '#{result}'")
      end

      result
    end

    # Returns [(arr)regions, (bool)observed, (bool)informal]
    def parse_options(*options)
      options.flatten!

      #TODO This is garbage. These two deletes MUST come before the
      # parse_regions call, otherwise it thinks that :observed and :informal
      # are regions to parse. We should be splitting these things out.

      opts = []
      opts << :observed if options.delete(:observed)
      opts << :informal if options.delete(:informal)

      if options.empty? || options.include?(:any)
        regions = Holidays.repository.regions
      else
        regions = options.flat_map { |region| Holidays.repository.lookup_region(region.to_sym) }.uniq
      end

      return regions, opts
    end
  end
end