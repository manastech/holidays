module Holidays
  module Finder
    class << self
      # Returns [(arr)regions, (bool)observed, (bool)informal]
      def parse_options(*options)
        options.flatten!

        #TODO This is garbage. These two deletes MUST come before the
        # parse_regions call, otherwise it thinks that :observed and :informal
        # are regions to parse. We should be splitting these things out.

        opts = []
        opts << :observed if options.delete(:observed)
        opts << :informal if options.delete(:informal)

        regions = parse_regions!(options)

        return regions, opts
      end

      private

      # Check regions against list of supported regions and return an array of
      # symbols.
      #
      # If a wildcard region is found (e.g. :ca_) it is expanded into all
      # of its available sub regions.
      def parse_regions!(regions)
        regions = [regions] unless regions.kind_of?(Array)

        if regions.empty?
          regions = [:any]
        else
          regions = regions.collect { |r| r.to_sym }
        end

        raise InvalidRegion unless regions.all? { |r| region_is_valid?(r) }

        loaded_regions = []

        regions_repo = Holidays::Factory::Definition.regions_repository

        if regions.include?(:any)
          regions_repo.all_generated.each do |r|
            if regions_repo.loaded?(r)
              loaded_regions << r
              next
            end

            target = regions_repo.parent_region_lookup(r)
            load_region!(target)

            loaded_regions << r
          end
        else
          regions.each do |r|
            if is_wildcard?(r)
              prefix = get_region_parent(r)
              loaded_regions << load_region!(prefix)
            else
              parent = regions_repo.parent_region_lookup(r)

              target = parent || r

              puts "Loading target region #{target}"

              if regions_repo.loaded?(target)
                loaded_regions << r
                next
              end

              load_region!(target)

              loaded_regions << r
            end
          end
        end

        loaded_regions.flatten.compact.uniq
      end

      def region_is_valid?(r)
        return false unless r.is_a?(Symbol)

        if is_wildcard? r
          region = get_region_parent(r)
        else
          region = r
        end


        puts "Generated regions: #{Factory::Definition.regions_repository.all_generated}"
        puts "Looking up region: #{region}"

        (region == :any ||
         Factory::Definition.regions_repository.loaded?(region) ||
         Factory::Definition.regions_repository.all_generated.include?(region))
      end

      def is_wildcard?(r)
        r.to_s.end_with?('_') 
      end

      def get_region_parent(region)
        region.to_s.split('_').first.to_sym
      end
  
      def load_region!(region)
        region_definition_file = "#{Holidays::configuration.full_definitions_path}/#{region}"
        require region_definition_file

        target_region_module = Module.const_get("Holidays").const_get(region.upcase)

        Holidays::Factory::Definition.merge(
          region,
          target_region_module.holidays_by_month,
          target_region_module.custom_methods,
        )

        target_region_module.defined_regions
      rescue  NameError, LoadError => e
        raise UnknownRegionError.new(e), "Could not load region prefix: #{region.to_s}"
      end
    end
  end
end

