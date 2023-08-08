## encoding: utf-8
$:.unshift File.dirname(__FILE__)

require 'date'
require 'digest/md5'
require 'holidays/finder'
require 'holidays/errors'
require 'holidays/generator'
require 'holidays/repository'
require 'holidays/cache_repository'
require 'holidays/date_calculator'

module Holidays
  WEEKS = {:first => 1, :second => 2, :third => 3, :fourth => 4, :fifth => 5, :last => -1, :second_last => -2, :third_last => -3}
  MONTH_LENGTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  DAY_SYMBOLS = Date::DAYNAMES.collect { |n| n.downcase.intern }

  class << self
    # This needs to be called in order to seed the holidays repository with data. If you don't call this, then you can
    # add more definitions later with `load_new_definition` - but you still won't have the global custom methods
    # like `easter(year)` available.
    def init_data(files_to_parse)
      Parser.parse_definition_files(files_to_parse).each do |definition|
        repository.add_region_definition(definition)
      end

      load_global_methods
    end

    def load_new_definition(definition)
      if definition.is_a? String
        # If it's a string, expect it be be a file path to a parseable region definition
        repository.add_region_definition Parser.parse_definition(definition)
      elsif definition.is_a? Holidays::RegionDefinition
        # If the user passes in their own RegionDefinition, then just add it directly
        repository.add_region_definition definition
      else
        raise ArgumentError, "load_new_definition expects a file path or a pre-loaded RegionDefinition"
      end
    end

    def any_holidays_during_work_week?(date, *options)
      monday = date - (date.wday - 1)
      friday = date + (5 - date.wday)

      holidays = between(monday, friday, *options)

      holidays && holidays.count > 0
    end

    def on(date, *options)
      between(date, date, *options)
    end

    def between(start_date, end_date, *options)
      raise ArgumentError unless start_date && end_date

      # remove the timezone
      start_date = start_date.new_offset(0) + start_date.offset if start_date.respond_to?(:new_offset)
      end_date = end_date.new_offset(0) + end_date.offset if end_date.respond_to?(:new_offset)

      start_date, end_date = get_date(start_date), get_date(end_date)

      raise ArgumentError if end_date < start_date

      if cached_holidays = cache.find(start_date, end_date, options)
        return cached_holidays
      end

      Holidays::Finder.between(start_date, end_date, options)
    end

    #FIXME All other methods start with a date and require a date. For the next
    #      major version bump we should take the opportunity to change this
    #      signature to match, e.g. next_holidays(from_date, count, options)
    def next_holidays(holidays_count, options, from_date = Date.today)
      raise ArgumentError unless holidays_count
      raise ArgumentError if options.empty?
      raise ArgumentError unless options.is_a?(Array)

      # remove the timezone
      from_date = from_date.new_offset(0) + from_date.offset if from_date.respond_to?(:new_offset)

      from_date = get_date(from_date)

      Holidays::Finder.next_holiday(holidays_count, from_date, options)
    end

    #FIXME All other methods start with a date and require a date. For the next
    #      major version bump we should take the opportunity to change this
    #      signature to match, e.g. year_holidays(from_date, options)
    def year_holidays(options, from_date = Date.today)
      raise ArgumentError if options.empty?
      raise ArgumentError unless options.is_a?(Array)

      # remove the timezone
      from_date = from_date.new_offset(0) + from_date.offset if from_date.respond_to?(:new_offset)
      from_date = get_date(from_date)

      Holidays::Finder.year_holiday(from_date, options)
    end

    def cache_between(start_date, end_date, *options)
      start_date, end_date = get_date(start_date), get_date(end_date)
      cache_data = between(start_date, end_date, *options)

      cache.cache_between(start_date, end_date, cache_data, options)
    end

    def available_regions
      repository.regions
    end

    def region_metadata(region_name)
      repository.region_metadata[region_name.to_sym]
    end

    def repository
      @repository ||= Repository.new
    end

    def cache
      @cache_repository ||= CacheRepository.new
    end
    
    private

    def load_global_methods
      #FIXME I need a better way to do this. I'm thinking of putting these 'common' methods
      # into some kind of definition file so it can be loaded automatically but I'm afraid
      # of making that big of a breaking API change since these are public. For the time
      # being I'll load them manually like this.
      #
      # NOTE: These are no longer public! We can do whatever we want here!
      global_methods = [
        Holidays::CustomMethod.from_proc("easter", "year", Holidays::DateCalculator::Easter::Gregorian.method(:calculate_easter_for).to_proc),
        Holidays::CustomMethod.from_proc("orthodox_easter", "year", Holidays::DateCalculator::Easter::Gregorian.method(:calculate_orthodox_easter_for).to_proc),
        Holidays::CustomMethod.from_proc("orthodox_easter_julian", "year", Holidays::DateCalculator::Easter::Julian.method(:calculate_orthodox_easter_for).to_proc),
        Holidays::CustomMethod.from_proc("to_monday_if_sunday", "date", Holidays::DateCalculator.method(:to_monday_if_sunday).to_proc),
        Holidays::CustomMethod.from_proc("to_monday_if_weekend", "date", Holidays::DateCalculator.method(:to_monday_if_weekend).to_proc),
        Holidays::CustomMethod.from_proc("to_weekday_if_boxing_weekend", "date", Holidays::DateCalculator.method(:to_weekday_if_boxing_weekend).to_proc),
        Holidays::CustomMethod.from_proc("to_weekday_if_boxing_weekend_from_year", "year", Holidays::DateCalculator.method(:to_weekday_if_boxing_weekend_from_year).to_proc),
        Holidays::CustomMethod.from_proc("to_weekday_if_weekend", "date", Holidays::DateCalculator.method(:to_weekday_if_weekend).to_proc),
        Holidays::CustomMethod.from_proc("calculate_day_of_month", "year, month, day, wday", Holidays::DateCalculator.method(:day_of_month).to_proc),
        Holidays::CustomMethod.from_proc("to_weekday_if_boxing_weekend_from_year_or_to_tuesday_if_monday", "year", Holidays::DateCalculator.method(:to_weekday_if_boxing_weekend_from_year_or_to_tuesday_if_monday).to_proc),
        Holidays::CustomMethod.from_proc("to_tuesday_if_sunday_or_monday_if_saturday", "date", Holidays::DateCalculator.method(:to_tuesday_if_sunday_or_monday_if_saturday).to_proc),
        Holidays::CustomMethod.from_proc("lunar_to_solar", "year, month, day, region", Holidays::DateCalculator::Lunar.method(:to_solar).to_proc) ,
      ]

      global_methods.each do |method|
        Holidays.repository.custom_methods[method.method_key] = method
      end
    end
    

    def get_date(date)
      if date.respond_to?(:to_date)
        date.to_date
      else
        Date.civil(date.year, date.mon, date.mday)
      end
    end
  end
end

