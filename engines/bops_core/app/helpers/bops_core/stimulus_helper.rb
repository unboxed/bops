# frozen_string_literal: true

module BopsCore
  module StimulusHelper
    def stimulus_tag(controller, values: {}, &)
      tag.div(data: {controller:}.merge(stimulus_values(controller, values)), &)
    end

    private

    def stimulus_values(controller, hash)
      hash.transform_keys { |key| :"#{controller}_#{key}_value" }
    end
  end
end
