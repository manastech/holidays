require File.expand_path(File.dirname(__FILE__)) + '/../../test_helper'
require 'holidays/definition/metadata.rb'

class MetadataSpec < Test::Unit::TestCase
  def test_properly_parses_correct_yaml
    yaml_source = <<-YAML
metadata:
  region: us
  name: United States
  description: Test metadata
  unknown_prop: Something
YAML

    metadata = Holidays::Metadata.from_yaml YAML.load(yaml_source)['metadata']

    assert_equal metadata[:region], :us
    assert_equal metadata[:name], "United States"
    assert_equal metadata[:description], "Test metadata"
    assert_equal metadata[:unknown_prop], "Something"
  end

  def test_fails_when_missing_region
    yaml_source = <<-YAML
metadata:
  name: United States
YAML

    assert_raise(ArgumentError) do
      metadata = Holidays::Metadata.from_yaml YAML.load(yaml_source)['metadata']
    end
  end

  def test_fails_when_missing_name
    yaml_source = <<-YAML
metadata:
  region: us
YAML

    assert_raise(ArgumentError) do
      metadata = Holidays::Metadata.from_yaml YAML.load(yaml_source)['metadata']
    end

  end
end
