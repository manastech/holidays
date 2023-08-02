require 'holidays/definition/entity/test'

module Holidays
  # `Test` refers to the tests that a holiday definition author can include in a definition file. These tests help us
  # verify that the definitions - especially ones utilizing custom methods - will produce the expected results.
  #
  # The test format is pretty simple. For each test, the author gives one to many dates plus a list of holidays (or none)
  # that are expected to occur on that/those date(s). `to_source` converts these test YAMLs into runnable Ruby code.
  class Test    
    attr_accessor :dates
    attr_accessor :regions
    attr_accessor :options
    attr_accessor :name
    
    def initialize(dates, regions, options, name, is_holiday)
      # name can be nil, otherwise it has to be a string
      raise ArgumentError unless name.is_a?(String) || name.nil?
      
      @dates = dates
      @regions = regions
      @options = options
      @name = name
      @is_holiday = is_holiday
    end

    def self.from_yaml(test_yaml)
      given = t["given"]
      expect = t["expect"]

      dates = if given["date"].is_a?(Array)
        given["date"]
      else
        [given["date"]]
      end

      options = if given["options"].is_a?(Array)
        given["options"]
      else
        [given["option"]]
      end

      is_holiday = expect["holiday"].nil? ? true : !!expect["holiday"]

      Test.new(
        dates.map { |d| DateTime.parse(d) },
        given["regions"].map(&:to_sym),
        given["options"].map(&:to_sym),
        expect["name"],
        is_holiday,
      )
    end

    def to_source
      src = ""

      dates.each do |d|
        date = "Date.civil(#{d.year}, #{d.month}, #{d.day})"

        holiday_call = "Holidays.on(#{date}, #{regions}"

        if options
          holiday_call += ", #{options.map(&:to_sym)}"
        end

        if holiday?
          src += "assert_equal \"#{name}\", (#{holiday_call})[0] || {})[:name]\n"
        else
          src += "assert_nil (#{holiday_call})[0] || {})[:name]\n"
        end
      end

      src
    end

    def holiday?
      @is_holiday
    end
  end
end
