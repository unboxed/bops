# frozen_string_literal: true

class AddPlanningPolicyAndGuidanceToLocalAuthority < ActiveRecord::Migration[7.1]
  class LocalAuthority < ActiveRecord::Base; end

  def change
    add_column :local_authorities, :planning_policy_and_guidance, :string

    up_only do
      LocalAuthority.reset_column_information

      LocalAuthority.where(subdomain: "planx")
        .update_all(planning_policy_and_guidance: "http://example.com")

      LocalAuthority.where(subdomain: "lambeth")
        .update_all(planning_policy_and_guidance: "https://www.lambeth.gov.uk/planning-building-control/planning-policy-guidance")

      LocalAuthority.where(subdomain: "southwark")
        .update_all(planning_policy_and_guidance: "https://www.southwark.gov.uk/planning-and-building-control/planning-policy-and-guidance")

      LocalAuthority.where(subdomain: "buckinghamshire")
        .update_all(planning_policy_and_guidance: "https://www.buckinghamshire.gov.uk/planning-and-building-control/planning-policy/")

      LocalAuthority.where(subdomain: "gloucester")
        .update_all(planning_policy_and_guidance: "https://www.gloucester.gov.uk/planning-development/planning-policy/")

      LocalAuthority.where(subdomain: "camden")
        .update_all(planning_policy_and_guidance: "https://www.camden.gov.uk/planning-policy")

      LocalAuthority.where(subdomain: "medway")
        .update_all(planning_policy_and_guidance: "https://www.medway.gov.uk/info/200149/planning_policy")
    end
  end
end
