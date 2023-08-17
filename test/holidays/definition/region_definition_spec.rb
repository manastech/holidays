require File.expand_path(File.dirname(__FILE__)) + '/../../test_helper'
require 'holidays/definition/region_definition.rb'

class RegionDefinitionSpec < Test::Unit::TestCase
  def test_parses_correct_yaml
    yaml_source = <<-YAML
metadata:
  region: us
  name: United States
months:
  1:
    - name: New Year's Day
      mday: 1
      type: public_holiday
  5:
    - name: Memorial Day
      week: -1
      wday: 1
      type: public_holiday
YAML

    region_def = Holidays::RegionDefinition.from_yaml YAML.load(yaml_source)

    assert_equal region_def.region, :us
    assert_equal region_def.metadata[:name], "United States"
    assert_not_empty region_def.month_rules

    region_def.month_rules.each do |month, rules|
      rules.each { |rule| assert_equal rule.regions, [:us] }
    end
  end
end
