# encoding: utf-8
module Holidays
  # This file is generated by the Ruby Holidays gem.
  #
  # Definitions loaded: definitions/se.yaml
  #
  # To use the definitions in this file, load it right after you load the
  # Holiday gem:
  #
  #   require 'holidays'
  #   require 'generated_definitions/se'
  #
  # All the definitions are available at https://github.com/holidays/holidays
  module SE # :nodoc:
    def self.defined_regions
      [:se]
    end

    def self.holidays_by_month
      {
              0 => [{:function => "easter(year)", :function_arguments => [:year], :function_modifier => -2, :name => "Långfredagen", :regions => [:se]},
            {:function => "easter(year)", :function_arguments => [:year], :function_modifier => -1, :type => :informal, :name => "Påskafton", :regions => [:se]},
            {:function => "easter(year)", :function_arguments => [:year], :name => "Påskdagen", :regions => [:se]},
            {:function => "easter(year)", :function_arguments => [:year], :function_modifier => 1, :name => "Annandag påsk", :regions => [:se]},
            {:function => "easter(year)", :function_arguments => [:year], :function_modifier => 39, :name => "Kristi himmelsfärdsdag", :regions => [:se]},
            {:function => "easter(year)", :function_arguments => [:year], :function_modifier => 49, :name => "Pingstdagen", :regions => [:se]},
            {:function => "se_alla_helgons_dag(year)", :function_arguments => [:year], :name => "Alla helgons dag", :regions => [:se]}],
      1 => [{:mday => 1, :name => "Nyårsdagen", :regions => [:se]},
            {:mday => 6, :name => "Trettondedag jul", :regions => [:se]}],
      5 => [{:mday => 1, :name => "Första maj", :regions => [:se]}],
      6 => [{:mday => 6, :name => "Nationaldagen", :regions => [:se]},
            {:function => "se_midsommardagen(year)", :function_arguments => [:year], :name => "Midsommardagen", :regions => [:se]},
            {:function => "se_midsommardagen(year)", :function_arguments => [:year], :function_modifier => -1, :type => :informal, :name => "Midsommarafton", :regions => [:se]}],
      12 => [{:mday => 24, :type => :informal, :name => "Julafton", :regions => [:se]},
            {:mday => 25, :name => "Juldagen", :regions => [:se]},
            {:mday => 26, :name => "Annandag jul", :regions => [:se]},
            {:mday => 31, :type => :informal, :name => "Nyårsafton", :regions => [:se]}]
      }
    end

    def self.custom_methods
      {
        "se_midsommardagen(year)" => Proc.new { |year|
date = Date.civil(year,6,20)
date += (6 - date.wday)
date
},

"se_alla_helgons_dag(year)" => Proc.new { |year|
date = Date.civil(year,10,31)
date += (6 - date.wday)
date
},


      }
    end
  end
end