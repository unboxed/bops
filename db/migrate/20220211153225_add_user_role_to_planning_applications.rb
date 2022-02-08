# frozen_string_literal: true

class AddUserRoleToPlanningApplications < ActiveRecord::Migration[6.1]
  class PlanningApplication < ApplicationRecord
    enum user_role: { applicant: 0, agent: 1, proxy: 2 }
  end

  def up
    add_column :planning_applications, :user_role, :integer

    PlanningApplication.find_each do |planning_application|
      if planning_application.agent_email.present? || planning_application.agent_phone.present?
        planning_application.agent!
      else
        planning_application.applicant!
      end
    end
  end

  def down
    remove_column :planning_applications, :user_role, :integer
  end
end
