require 'holidays/definition/repository/holidays_by_month'
require 'holidays/definition/repository/regions'
require 'holidays/definition/repository/cache'
require 'holidays/definition/repository/proc_result_cache'
require 'holidays/definition/repository/custom_methods'

module Holidays
  module Factory
    module Definition
      class << self
        def merge(target_regions, target_holidays, target_custom_methods)
          #FIXME Does this need to come in this exact order? God I hope not.
          # If not then we should swap the order so it matches the init.
          regions_repository.add(target_regions)
          holidays_by_month_repository.add(target_holidays)
          custom_methods_repository.add(target_custom_methods)
        end

        def custom_method_proc_decorator
          Holidays::Definition::Decorator::CustomMethodProc.new
        end

        def holidays_by_month_repository
          @holidays_repo ||= Holidays::Definition::Repository::HolidaysByMonth.new
        end

        def regions_repository
          @regions_repo ||= Holidays::Definition::Repository::Regions.new(
            Holidays::REGIONS,
            Holidays::PARENT_REGION_LOOKUP,
          )
        end

        def cache_repository
          @cache_repo ||= Holidays::Definition::Repository::Cache.new
        end

        def proc_result_cache_repository
          @proc_result_cache_repo ||= Holidays::Definition::Repository::ProcResultCache.new
        end

        def custom_methods_repository
          @custom_methods_repository ||= Holidays::Definition::Repository::CustomMethods.new
        end

        def loader
          Holidays::Definition::Context::Load.new(
            merger,
            Holidays::configuration.full_definitions_path,
          )
        end
      end
    end
  end
end
