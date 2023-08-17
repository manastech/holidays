require File.expand_path(File.dirname(__FILE__)) + '/../../test_helper'
require 'holidays/definition/custom_method.rb'

class CustomMethodSpec < Test::Unit::TestCase
  def test_parse_correct_yaml
    yaml_source = <<-YAML
to_tuesday:
  arguments: date
  ruby: |
      case date.wday
      when 3
        date += 6
      when 4
        date += 5
      when 5
        date += 4
      when 6
        date += 3
      when 0
        date += 2
      end

      date
YAML

    custom_method = Holidays::CustomMethod.from_yaml "to_tuesday", YAML.load(yaml_source)['to_tuesday']

    assert_equal custom_method.name, "to_tuesday"
    assert_equal custom_method.arguments, [:date]
    assert_not_empty custom_method.source
  end

  def test_custom_method_produces_correct_result
    yaml_source = <<-YAML
to_tuesday:
  arguments: date
  ruby: |
      case date.wday
      when 0
        date += 2
      when 1
        date += 1
      when 3
        date += 6
      when 4
        date += 5
      when 5
        date += 4
      when 6
        date += 3
      end

      date
YAML

    custom_method = Holidays::CustomMethod.from_yaml "to_tuesday", YAML.load(yaml_source)['to_tuesday']

    test_dates = (0...6).map { |wday| Date.new(2023, 01, 1 + wday) }
    test_dates.each do |d|
      res = custom_method.to_proc.call(d)
      assert_equal 2, res.wday
    end
  end
end

