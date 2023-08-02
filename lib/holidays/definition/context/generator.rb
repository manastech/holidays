require 'yaml'
require 'holidays/definition/custom_method.rb'
require 'holidays/definition/parser/test.rb'
require 'holidays/definition/generator.rb'

module Holidays
  class << self
    def parse_definition_files(files)
      raise ArgumentError, "Must have at least one file to parse" if files.nil? || files.empty?

      all_regions = []
      all_rules_by_month = {}
      all_custom_methods = {}
      all_metadata_by_region = {}
      all_tests = []

      files.flatten!

      files.each do |file|
        definition_file = YAML.load_file(file)

        custom_methods = {}
        definition_file["methods"].each do |name, method_props|
          cm = Holidays::CustomMethod.from_yaml(name, method_props)
          custom_methods[cm.method_key] = cm
        end

        rules_by_month = parse_month_definitions(definition_file['months'], custom_methods)

        if definition_file['metadata']
          metadata_region, metadata = parse_metadata_definitions(definition_file['metadata'])
          metadata_region_sym = metadata_region.to_sym if metadata_region
          if metadata_region_sym and !all_metadata_by_region.key?(metadata_region_sym)
            all_metadata_by_region[metadata_region_sym] = metadata
          end

          all_regions << metadata_region_sym 

          rules_by_month.each do |month, rules|
            rules.each do |rule|
              rule[:regions] = [metadata_region_sym]
            end
          end
        end

        all_rules_by_month.merge!(rules_by_month) { |month, existing, new|
          existing << new
          existing.flatten!
        }

        #FIXME This is a problem. We will have a 'global' list of methods. That's always bad. What effects will this have?
        # This is an existing problem (just so we are clear). An issue would be extremely rare because we are generally parsing
        # single files/custom files. But it IS possible that we would parse a bunch of things at the same time and step
        # on each other so we need a solution.
        all_custom_methods.merge!(custom_methods)

        all_tests += Holidays::TestParser.parse_tests(definition_file['tests'])
      end

      all_regions.uniq!

      [all_regions, all_rules_by_month, all_metadata_by_region, all_custom_methods, all_tests]
    end

    def generate_definition_source(module_name, files, regions, rules_by_month, custom_methods, tests)
      month_strings = generate_month_definition_strings(rules_by_month, custom_methods)

      # Build the custom methods string
      custom_method_string = ''
      custom_methods.each do |key, code|
        custom_method_string << code.to_source + ",\n\n"
      end

      module_src = Holidays::Definition::Generator.generate_module_source(module_name, files, regions, month_strings, custom_method_string)
      test_src = Holidays::Definition::Generator.generate_test_source(module_name, files, tests)

      return module_src, test_src || ''
    end

    private

    def parse_metadata_definitions(metadata_definitions)
      metadata_definitions.transform_keys!(&:to_sym) if metadata_definitions.is_a?(Hash)

      if metadata_definitions[:region]
        metadata_region = metadata_definitions[:region].to_sym if metadata_definitions[:region]
        metadata_definitions.delete(:region)
      end
    
      [metadata_region, metadata_definitions]
    end

    def parse_month_definitions(month_definitions, parsed_custom_methods)
      return {} unless month_definitions
      rules_by_month = {}

      month_definitions.each do |month, definitions|
        rules_by_month[month] = [] unless rules_by_month[month]
        definitions.each do |definition|
          rule = {}

          definition.each do |key, val|
            val.transform_keys!(&:to_sym) if val.is_a?(Hash)
            rule[key.to_sym] = val
          end

          if rule[:year_ranges] && rule[:year_ranges].key?(:between)
            start_year = rule[:year_ranges][:between]["start"].to_i
            end_year = rule[:year_ranges][:between]["end"].to_i

            rule[:year_ranges][:between] = Range.new(start_year, end_year)
          end

          exists = false
          rules_by_month[month].each do |ex|
            if ex[:name] == rule[:name] and ex[:wday] == rule[:wday] and ex[:mday] == rule[:mday] and ex[:week] == rule[:week] and ex[:type] == rule[:type] and ex[:function] == rule[:function] and ex[:observed] == rule[:observed] and ex[:year_ranges] == rule[:year_ranges]
              ex[:regions] << rule[:regions].flatten
              exists = true
            end
          end

          unless exists
            # This will add in the custom method arguments so they are immediately
            # available for 'on the fly' def loading.
            if rule[:function]
              rule[:function_arguments] = get_function_arguments(rule[:function], parsed_custom_methods)
            end

            rules_by_month[month] << rule
          end
        end
      end

      rules_by_month
    end

    #FIXME This should really be split out and tested with its own unit tests.
    def generate_month_definition_strings(rules_by_month, parsed_custom_methods)
      month_strings = []

      rules_by_month.each do |month, rules|
        month_string = "      #{month.to_s} => ["
        rule_strings = []
        rules.each do |rule|
          string = '{'
          if rule[:mday]
            string << ":mday => #{rule[:mday]}, "
          end

          if rule[:function]
            string << ":function => \"#{rule[:function].to_s}\", "

            # We need to add in the arguments so we can know what to send in when calling the custom proc during holiday lookups.
            # NOTE: the allowed arguments are enforced in the custom methods parser.
            string << ":function_arguments => #{get_function_arguments(rule[:function], parsed_custom_methods)}, "

            if rule[:function_modifier]
              string << ":function_modifier => #{rule[:function_modifier].to_s}, "
            end
          end

          # This is the 'else'. It is possible for mday AND function
          # to be set but this is the fallback. This whole area
          # needs to be reworked!
          if string == '{'
            string << ":wday => #{rule[:wday]}, :week => #{rule[:week]}, "
          end

          if rule[:year_ranges] && rule[:year_ranges].is_a?(Hash)
            selector = rule[:year_ranges].keys.first
            value = rule[:year_ranges][selector]

            string << ":year_ranges => { :#{selector} => #{value} },"
          end

          if rule[:observed]
            string << ":observed => \"#{rule[:observed].to_s}\", "
            string << ":observed_arguments => #{get_function_arguments(rule[:observed], parsed_custom_methods)}, "
          end

          if rule[:type]
            string << ":type => :#{rule[:type]}, "
          end

          # shouldn't allow the same region twice
          string << ":name => \"#{rule[:name]}\", :regions => [:" + rule[:regions].uniq.join(', :') + "]}"
          rule_strings << string
        end
        month_string << rule_strings.join(",\n            ") + "]"
        month_strings << month_string
      end

      return month_strings
    end

    # This method sucks. The issue here is that the custom methods repo has the 'general' methods (like easter)
    # but the 'parsed_custom_methods' have the recently parsed stuff. We don't load those until they are needed later.
    # This entire file is a refactor target so I am adding some tech debt to get me over the hump.
    # What we should do is ensure that all custom methods are loaded into the repo as soon as they are parsed
    # so we only have one place to look.
    def get_function_arguments(function_id, parsed_custom_methods)
      if method = Holidays::Factory::Definition.custom_methods_repository.find(function_id)
        method.parameters.collect { |arg| arg[1] }
      elsif method = parsed_custom_methods[function_id]
        method.arguments.collect { |arg| arg.to_sym }
      end
    end
  end 
end

