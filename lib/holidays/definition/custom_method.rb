module Holidays
  # `CustomMethod`s allow definition writers to write custom Ruby code that modifies the date of a holiday,
  # based on the initial date and/or holiday region.
  class CustomMethod
    VALID_ARGUMENTS = ["date", "year", "month", "day", "region"]

    attr_accessor :name
    attr_accessor :arguments 
    attr_accessor :source

    def initialize(name, arguments, source)
      raise ArgumentError if name.nil? || name.empty? || !name.is_a?(String)
      raise ArgumentError if source.nil? || source.empty? || !source.is_a?(String)
      raise ArgumentError unless arguments.all? { |arg| VALID_ARGUMENTS.include? arg }

      @name = name
      @arguments = arguments
      @source = source
    end

    # Initialize a new `CustomMethod` from a YAML object. The name of the method is not
    # expected on the YAML object properties, it should be provided separately. In most circumstances,
    # this name should come from the key used when defining the method in the definition file.
    def self.from_yaml(name, definition)
      arguments = definition["arguments"].split(",").map(&:strip)
      
      CustomMethod.new(name, arguments, definition["ruby"])      
    end

    # Serialize this custom method into Ruby code that can be loaded later.
    def to_source
      "\"#{name}(#{args_string})\" => Proc.new { |#{args_string}|\n#{source}}"
    end

    # Return a new Proc instance based on the arguments & source code of this custom method.
    def to_proc
      eval("Proc.new { |#{args_string}|
           #{source}
      }")
    end

    def method_key
      "#{name}(#{args_string})"
    end

    def args_string
      arguments.join(", ")[0..-1]
    end

  end
end

