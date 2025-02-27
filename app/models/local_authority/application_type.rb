# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  class ApplicationType < ApplicationRecord
    belongs_to :local_authority
    belongs_to :application_type

    scope :with_code, ->(code) { joins(:application_type).where(application_types: {code: code}) }
    scope :pre_app, -> { with_code("preApp") }

    with_options on: :application_type_overrides do
      validates :determination_period_days, presence: true, if: :pre_app?
      validates :determination_period_days, numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 99}, if: :pre_app?
    end

    delegate :code, to: :application_type

    private

    def pre_app?
      application_type&.code == "preApp"
    end
  end
end
