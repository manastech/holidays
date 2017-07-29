# encoding: utf-8
module Holidays
  # This file is generated by the Ruby Holidays gem.
  #
  # Definitions loaded: definitions/tr.yaml
  #
  # All the definitions are available at https://github.com/holidays/holidays
  module TR # :nodoc:
    def self.defined_regions
      [:tr]
    end

    def self.holidays_by_month
      {
              0 => [{:function => "ramadan_feast(year)", :function_arguments => [:year], :name => "Ramazan Bayramı", :regions => [:tr]},
            {:function => "ramadan_feast(year)", :function_arguments => [:year], :function_modifier => 1, :name => "Ramazan Bayramı (ikinci tatil)", :regions => [:tr]},
            {:function => "ramadan_feast(year)", :function_arguments => [:year], :function_modifier => 2, :name => "Ramazan Bayramı (üçüncü tatil)", :regions => [:tr]},
            {:function => "sacrifice_feast(year)", :function_arguments => [:year], :name => "Kurban Bayramı", :regions => [:tr]},
            {:function => "sacrifice_feast(year)", :function_arguments => [:year], :function_modifier => 1, :name => "Kurban Bayramı (ikinci tatil)", :regions => [:tr]},
            {:function => "sacrifice_feast(year)", :function_arguments => [:year], :function_modifier => 2, :name => "Kurban Bayramı (üçüncü tatil)", :regions => [:tr]},
            {:function => "sacrifice_feast(year)", :function_arguments => [:year], :function_modifier => 3, :name => "Kurban Bayramı (dördüncü tatil)", :regions => [:tr]}],
      1 => [{:mday => 1, :name => "Yılbaşı", :regions => [:tr]}],
      4 => [{:mday => 23, :name => "Ulusal Egemenlik ve Çocuk Bayramı", :regions => [:tr]}],
      5 => [{:mday => 1, :name => "Emek ve Dayanışma Günü", :regions => [:tr]},
            {:mday => 19, :name => "Atatürk'ü Anma Gençlik ve Spor Bayramı", :regions => [:tr]}],
      7 => [{:mday => 15,  :year_ranges => [{:after => 2016}],:name => "Demokrasi ve Milli Birlik Günü", :regions => [:tr]}],
      8 => [{:mday => 30, :name => "Zafer Bayramı", :regions => [:tr]}],
      10 => [{:mday => 29, :name => "Cumhuriyet Bayramı", :regions => [:tr]}]
      }
    end

    def self.custom_methods
      {
        "ramadan_feast(year)" => Proc.new { |year|
begin_of_ramadan_feast = {
    '2014' => Date.civil(2014, 7, 28),
    '2015' => Date.civil(2015, 7, 17),
    '2016' => Date.civil(2016, 7, 5),
    '2017' => Date.civil(2017, 6, 25),
    '2018' => Date.civil(2018, 6, 15),
    '2019' => Date.civil(2019, 6, 4)
}
begin_of_ramadan_feast[year.to_s]
},

"sacrifice_feast(year)" => Proc.new { |year|
begin_of_sacrifice_feast = {
    '2014' => Date.civil(2014, 10, 4),
    '2015' => Date.civil(2015, 9, 24),
    '2016' => Date.civil(2016, 9, 12),
    '2017' => Date.civil(2017, 9, 1),
    '2018' => Date.civil(2018, 8, 21),
    '2019' => Date.civil(2019, 8, 11)
}
begin_of_sacrifice_feast[year.to_s]
},


      }
    end
  end
end
