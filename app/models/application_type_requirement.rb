# frozen_string_literal: true

class ApplicationTypeRequirement < ApplicationRecord
  belongs_to :local_authority_requirement, class_name: "LocalAuthority::Requirement"
  belongs_to :application_type
  delegate :description, to: :local_authority_requirement
end
