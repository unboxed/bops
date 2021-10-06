# frozen_string_literal: true

class AddLocalAuthorityToUsersandPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_reference :users, :local_authority
    add_reference :planning_applications, :local_authority
  end
end
