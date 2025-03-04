# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  class ApplicationType < ApplicationRecord
    belongs_to :local_authority
    belongs_to :application_type, class_name: "::ApplicationType"

    has_many :planning_applications

    def determination_period_in_days
      super || application_type.determination_period_in_days
    end
  end

  has_many :application_types
end
