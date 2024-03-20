# frozen_string_literal: true

class AddConsultationStepsToApplicationTypes < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end

  STEPS = %w[neighbour consultee publicity].freeze

  def change
    up_only do
      ApplicationType.find_each do |type|
        if type.steps.include?("consultation")
          type.update!(features: type.features.merge("consultation_steps" => STEPS))
        end
      end
    end
  end
end
