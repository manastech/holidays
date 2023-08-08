module Holidays
  # `CustomMethod`s allow definition writers to write custom Ruby code that modifies the date of a holiday,
  # based on the initial date and/or holiday region.
  class CustomMethod
    VALID_ARGUMENTS = [:date, :year, :month, :day, :wday, :region]

    attr_accessor :name
    attr_accessor :arguments 
    attr_accessor :source

    def initialize(name, arguments, source, proc = nil)
      raise ArgumentError if name.nil? || name.empty? || !name.is_a?(String)
      raise ArgumentError if source.nil? || !source.is_a?(String)
      raise ArgumentError unless arguments.all? { |arg| VALID_ARGUMENTS.include? arg }

      @name = name
      @arguments = arguments
      @source = source
      @proc = proc if proc
      @result_cache = {}
    end

    # Initialize a new `CustomMethod` from a YAML object. The name of the method is not
    # expected on the YAML object properties, it should be provided separately. In most circumstances,
    # this name should come from the key used when defining the method in the definition file.
    def self.from_yaml(name, definition)
      arguments = definition["arguments"].split(",").map { |arg| arg.strip.to_sym }
      
      CustomMethod.new(name, arguments, definition["ruby"])      
    end

    def self.from_proc(name, arguments, proc)
      args = arguments.split(',').map { |arg| arg.strip.to_sym }
      CustomMethod.new(name, args, "", proc)
    end

    # Call this method with the given inputs. `input_args` should be a hash which maps each input param name
    # (i.e., `:year`) to a value.
    #
    # Calls will be cached to avoid extra computation for the same dates.
    def call(input_args)
      args_list = []
      # Iterate over all of the arguments that this method takes, and try to get the correct values from
      # the input list.
      arguments.each do |arg|
        if arg == :date
          args_list << Date.civil(input_args[:year], input_args[:month], input_args[:day])
        elsif input = input_args[arg]
          args_list << input
        else
          raise ArgumentError, "Missing required argument #{arg} for custom method #{name}"
        end
      end

      cache_key = Digest::MD5.hexdigest("#{args_list.join('_')}")
      @result_cache[cache_key] = to_proc.call(*args_list) unless @result_cache[cache_key]
      @result_cache[cache_key]      
    end

    # Serialize this custom method into Ruby code that can be loaded later.
    def to_source
      "\"#{name}(#{args_string})\" => Proc.new { |#{args_string}|\n#{source}}"
    end

    # Return a new Proc instance based on the arguments & source code of this custom method.
    def to_proc
      @proc ||= eval("Proc.new { |#{args_string}| #{source} }")
    end

    def method_key
      "#{name}(#{args_string})"
    end

    def args_string
      arguments.join(", ")[0..-1]
    end

  end
end

