# frozen_string_literal: true

class ApplicationTypesCondition < ApplicationRecord
  belongs_to :application_type
  belongs_to :condition
end
