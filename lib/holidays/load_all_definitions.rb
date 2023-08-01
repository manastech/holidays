require "holidays/date_calculator/day_of_month"
require "holidays/date_calculator/lunar_date"
require "holidays/date_calculator/weekend_modifier"

module Holidays
  #TODO This file should be renamed. It's no longer about definitions, really.
  class InitializeDefinitions
    class << self
      def call
        load_global_methods
        load_regions
      end

      def load_global_methods
        #FIXME I need a better way to do this. I'm thinking of putting these 'common' methods
        # into some kind of definition file so it can be loaded automatically but I'm afraid
        # of making that big of a breaking API change since these are public. For the time
        # being I'll load them manually like this.
        #
        # NOTE: These are no longer public! We can do whatever we want here!
        global_methods = {
          "easter(year)" => Holidays::DateCalculator::Easter::Gregorian.method(:calculate_easter_for).to_proc,
          "orthodox_easter(year)" => Holidays::DateCalculator::Easter::Gregorian.method(:calculate_orthodox_easter_for).to_proc,
          "orthodox_easter_julian(year)" => Holidays::DateCalculator::Easter::Julien.method(:calculate_orthodox_easter_for).to_proc,
          "to_monday_if_sunday(date)" => Holidays::DateCalculator.method(:to_monday_if_sunday).to_proc,
          "to_monday_if_weekend(date)" => Holidays::DateCalculator.method(:to_monday_if_weekend).to_proc,
          "to_weekday_if_boxing_weekend(date)" => Holidays::DateCalculator.method(:to_weekday_if_boxing_weekend).to_proc,
          "to_weekday_if_boxing_weekend_from_year(year)" => Holidays::DateCalculator.method(:to_weekday_if_boxing_weekend_from_year).to_proc,
          "to_weekday_if_weekend(date)" => Holidays::DateCalculator.method(:to_weekday_if_weekend).to_proc,
          "calculate_day_of_month(year, month, day, wday)" => Holidays::DateCalculator.method(:day_of_month).to_proc,
          "to_weekday_if_boxing_weekend_from_year_or_to_tuesday_if_monday(year)" => Holidays::DateCalculator.method(:to_weekday_if_boxing_weekend_from_year_or_to_tuesday_if_monday).to_proc,
          "to_tuesday_if_sunday_or_monday_if_saturday(date)" => Holidays::DateCalculator.method(:to_tuesday_if_sunday_or_monday_if_saturday).to_proc,
          "lunar_to_solar(year, month, day, region)" => Holidays::DateCalculator.method(:to_solar).to_proc, 
        }

        Factory::Definition.custom_methods_repository.add(global_methods)
      end

      def load_regions
        static_regions_definition = "#{Holidays::configuration.definitions_path}/REGIONS.rb"
        require static_regions_definition
      end
    end
  end
end
