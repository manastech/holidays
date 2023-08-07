require 'holidays/date_calculator/easter'
require 'holidays/date_calculator/lunar_date'

module Holidays::DateCalculator
  class << self
    # Calculate day of the month based on the week number and the day of the
    # week.
    #
    # ==== Parameters
    # [<tt>year</tt>]  Integer.
    # [<tt>month</tt>] Integer from 1-12.
    # [<tt>week</tt>]  One of <tt>:first</tt>, <tt>:second</tt>, <tt>:third</tt>,
    #                  <tt>:fourth</tt>, <tt>:fifth</tt> or <tt>:last</tt>.
    # [<tt>wday</tt>]  Day of the week as an integer from 0 (Sunday) to 6
    #                  (Saturday) or as a symbol (e.g. <tt>:monday</tt>).
    #
    # Returns an integer.
    #
    # ===== Examples
    # First Monday of January, 2008:
    #   Holidays::DateCalculator.day_of_month(2008, 1, :first, :monday)
    #   => 7
    #
    # Third Thursday of December, 2008:
    #   Holidays::DateCalculator.day_of_month(2008, 12, :third, :thursday)
    #   => 18
    #
    # Last Monday of January, 2008:
    #   Holidays::DateCalculator.day_of_month(2008, 1, :last, 1)
    #   => 28
    #--
    # see http://www.irt.org/articles/js050/index.htm
    def day_of_month(year, month, week, wday)
      raise ArgumentError, "Week parameter must be one of Holidays::WEEKS (provided #{week})." unless Holidays::WEEKS.include?(week) or Holidays::WEEKS.has_value?(week)

      unless wday.kind_of?(Numeric) and wday.between?(0,6) or Holidays::DAY_SYMBOLS.index(wday)
        raise ArgumentError, "Wday parameter must be an integer between 0 and 6 or one of Holidays::DAY_SYMBOLS."
      end

      week = Holidays::WEEKS[week] if week.kind_of?(Symbol)
      wday = Holidays::DAY_SYMBOLS.index(wday) if wday.kind_of?(Symbol)

      # :first, :second, :third, :fourth or :fifth
      if week > 0
        return ((week - 1) * 7) + 1 + ((wday - Date.civil(year, month,(week-1)*7 + 1).wday) % 7)
      end

      days = Holidays::MONTH_LENGTHS[month-1]

      days = 29 if month == 2 and Date.leap?(year)

      return days - ((Date.civil(year, month, days).wday - wday + 7) % 7) - (7 * (week.abs - 1))
    end

    # Move date to Monday if it occurs on a Saturday on Sunday.
    # Does not modify date if it is not a weekend.
    # Used as a callback function.
    def to_monday_if_weekend(date)
      return date unless date.wday == 6 || date.wday == 0
      to_next_weekday(date)
    end

    # Move date to Monday if it occurs on a Sunday.
    # Does not modify the date if it is not a Sunday.
    # Used as a callback function.
    def to_monday_if_sunday(date)
      return date unless date.wday == 0
      to_next_weekday(date)
    end

    # Move Boxing Day if it falls on a weekend, leaving room for Christmas.
    # Used as a callback function.
    def to_weekday_if_boxing_weekend(date)
      if date.wday == 6 || date.wday == 0
        date += 2
      elsif date.wday == 1 # https://github.com/holidays/holidays/issues/27
        date += 1
      end

      date
    end

    # if Christmas falls on a Saturday, move it to the next Monday (Boxing Day will be Sunday and potentially Tuesday)
    # if Christmas falls on a Sunday, move it to the next Tuesday (Boxing Day will go on Monday)
    #
    # if Boxing Day falls on a Saturday, move it to the next Monday (Christmas will go on Friday)
    # if Boxing Day falls on a Sunday, move it to the next Tuesday (Christmas will go on Saturday & Monday)
    def to_tuesday_if_sunday_or_monday_if_saturday(date)
      date += 2 if [0, 6].include?(date.wday)
      date
    end

    # Call to_weekday_if_boxing_weekend but first get date based on year
    # Used as a callback function.
    def to_weekday_if_boxing_weekend_from_year_or_to_tuesday_if_monday(year)
      to_weekday_if_boxing_weekend(Date.civil(year, 12, 26))
    end

    # Call to_weekday_if_boxing_weekend but first get date based on year
    # Used as a callback function.
    def to_weekday_if_boxing_weekend_from_year(year)
      to_tuesday_if_sunday_or_monday_if_saturday(Date.civil(year, 12, 26))
    end

    # Move date to Monday if it occurs on a Sunday or to Friday if it occurs on a
    # Saturday.
    # Used as a callback function.
    def to_weekday_if_weekend(date)
      date += 1 if date.wday == 0
      date -= 1 if date.wday == 6
      date
    end

    # Finds the next weekday. For example, if a 'Friday' date is received
    # it will return the following Monday. If Sunday then return Monday,
    # if Saturday return Monday, if Tuesday return Wednesday, etc.
    def to_next_weekday(date)
      case date.wday
      when 6
        date += 2
      when 5
        date += 3
      else
        date += 1
      end

      date
    end

  end
end
