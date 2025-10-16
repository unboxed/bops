# frozen_string_literal: true

class AddAgentBusinessNameAndApplicantAddressToPlanningApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :planning_applications, :agent_business_name, :string
    add_column :planning_applications, :applicant_address_1, :string
    add_column :planning_applications, :applicant_address_2, :string
    add_column :planning_applications, :applicant_town, :string
    add_column :planning_applications, :applicant_postcode, :string
  end
end
