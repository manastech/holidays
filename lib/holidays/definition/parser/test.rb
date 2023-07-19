require 'holidays/definition/entity/test'


module Holidays::TestParser
  class << self
    def parse_tests(tests)
      return [] if tests.nil?

      validate!(tests)

      tests.map do |t|
        given = t["given"]
        expect = t["expect"]

        Entity::Test.new(
          dates: parse_dates(given["date"]),
          regions: parse_regions(given["regions"]),
          options: parse_options(given["options"]),
          name: expect["name"],
          holiday?: is_holiday?(expect["holiday"]),
        )
      end
    end

    private

    def validate!(tests)
      raise ArgumentError unless tests.all? do |t|
        dates = t["given"]["date"]
        unless dates.is_a?(Array)
          dates = [ dates ]
        end

        name = t["expect"]["name"]
        holiday = t["expect"]["holiday"]

        valid_dates?(dates) &&
          valid_regions?(t["given"]["regions"]) &&
          valid_options?(t["given"]["options"]) &&
          valid_name?(name) &&
          valid_holiday?(holiday) &&
          (!name.nil? || !holiday.nil?)
      end
    end

    def valid_dates?(dates)
      return false unless dates

      dates.all? do |d|
        DateTime.parse(d)
        true
      rescue TypeError, ArgumentError
        false
      end
    end

    def valid_regions?(regions)
      return false unless regions

      regions.all? do |r|
        r.is_a?(String)
      end
    end

    # Can be missing
    def valid_name?(n)
      return true unless n
      n.is_a?(String)
    end

    # Can be missing
    def valid_holiday?(h)
      return true unless h
      h.is_a?(TrueClass)
    end

    # Okay to be missing and can be either string or array of strings
    def valid_options?(options)
      return true unless options

      if options.is_a?(Array)
        options.all? do |o|
          o.is_a?(String)
        end
      elsif options.is_a?(String)
        true
      else
        false
      end
    end

    def parse_dates(dates)
      unless dates.is_a?(Array)
        dates = [ dates ]
      end

      dates.map do |d|
        DateTime.parse(d)
      end
    end

    def parse_regions(regions)
      regions.map do |r|
        r.to_sym
      end
    end

    def parse_options(options)
      if options
        if options.is_a?(Array)
          options.map do |o|
            o.to_sym
          end
        else
          [ options.to_sym ]
        end
      end
    end

    # If flag is not present then default to 'true'
    def is_holiday?(flag)
      flag.nil? ? true : !!flag
    end
  end
end
