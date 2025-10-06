# frozen_string_literal: true

class AddCilRequirementToLocalAuthorities < ActiveRecord::Migration[7.2]
  class LocalAuthority < ApplicationRecord
    self.table_name = "local_authorities"

    has_many :requirements,
      class_name: "AddCilRequirementToLocalAuthorities::LocalAuthorityRequirement",
      inverse_of: :local_authority
  end

  class LocalAuthorityRequirement < ApplicationRecord
    self.table_name = "local_authority_requirements"

    belongs_to :local_authority,
      class_name: "AddCilRequirementToLocalAuthorities::LocalAuthority",
      inverse_of: :requirements
  end

  REQUIREMENT_ATTRIBUTES = {
    description: "Community Infrastructure Levy (CIL)",
    url: "https://www.planningportal.co.uk/permission/common-projects/community-infrastructure-levy",
    guidelines: <<~TEXT.strip,
      Your application may be liable for the Community Infrastructure Levy (CIL).
      This is a charge councils can apply to new developments to help fund infrastructure like schools, roads, and healthcare facilities.

      You can find more information about CIL on both the Planning Portal website or local council website.
    TEXT
    category: "other"
  }.freeze

  def up
    LocalAuthority.reset_column_information
    LocalAuthorityRequirement.reset_column_information

    LocalAuthority.find_each do |authority|
      next if authority.requirements.exists?(description: REQUIREMENT_ATTRIBUTES[:description])

      authority.requirements.create!(REQUIREMENT_ATTRIBUTES)
    end
  end

  def down
    LocalAuthorityRequirement.where(
      REQUIREMENT_ATTRIBUTES.slice(:description, :url, :category)
    ).delete_all
  end
end
