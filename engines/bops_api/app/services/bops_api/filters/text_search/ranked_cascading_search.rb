# frozen_string_literal: true

module BopsApi
  module Filters
    module TextSearch
      class RankedCascadingSearch < CascadingSearch
        STRATEGIES = [
          ReferenceSearch,
          PostcodeSearch,
          AddressSearch,
          RankedDescriptionSearch
        ].freeze

        private

        def query(params)
          params[:q].presence&.downcase&.strip
        end
      end
    end
  end
end
