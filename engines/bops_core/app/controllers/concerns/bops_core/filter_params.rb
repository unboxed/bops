# frozen_string_literal: true

module BopsCore
  module FilterParams
    extend ActiveSupport::Concern

    included do
      helper_method :filter_params
    end

    def filter_params
      params.permit(:query, :sort_key, :direction, status: [], application_type: []).to_h.symbolize_keys.merge(anchor: "tabs")
    end
  end
end
