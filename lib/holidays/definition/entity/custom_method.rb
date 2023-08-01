module Holidays
  module CustomMethod
    module Entity
      CustomMethod = Struct.new(:name, :arguments, :source) do
        def initialize(fields = {})
          super(*fields.values_at(*members))
        end
      end
    end
  end
end
