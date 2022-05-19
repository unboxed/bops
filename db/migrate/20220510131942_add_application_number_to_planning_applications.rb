# frozen_string_literal: true

class AddApplicationNumberToPlanningApplications < ActiveRecord::Migration[6.1]
  def up
    add_column :planning_applications, :application_number, :bigint

    add_index :planning_applications, %i[application_number local_authority_id], unique: true

    LocalAuthority.find_each do |local_authority|
      planning_applications = local_authority.planning_applications.order(created_at: :asc)

      planning_applications.find_each.with_index do |planning_application, i|
        planning_application.update(application_number: i + 100)
      end
    end

    change_column_null :planning_applications, :application_number, false
  end

  def down
    remove_column :planning_applications, :application_number, :bigint
  end
end
