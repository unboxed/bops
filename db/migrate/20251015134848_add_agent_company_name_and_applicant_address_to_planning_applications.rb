# frozen_string_literal: true

class AddAgentCompanyNameAndApplicantAddressToPlanningApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :planning_applications, :agent_company_name, :string
    add_column :planning_applications, :agent_address_1, :string
    add_column :planning_applications, :agent_address_2, :string
    add_column :planning_applications, :agent_town, :string
    add_column :planning_applications, :agent_county, :string
    add_column :planning_applications, :agent_postcode, :string
    add_column :planning_applications, :agent_country, :string
    add_column :planning_applications, :applicant_address_1, :string
    add_column :planning_applications, :applicant_address_2, :string
    add_column :planning_applications, :applicant_town, :string
    add_column :planning_applications, :applicant_county, :string
    add_column :planning_applications, :applicant_postcode, :string
    add_column :planning_applications, :applicant_country, :string
  end
end
