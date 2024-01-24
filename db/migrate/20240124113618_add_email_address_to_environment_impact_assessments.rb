# frozen_string_literal: true

class AddEmailAddressToEnvironmentImpactAssessments < ActiveRecord::Migration[7.0]
  def change
    add_column :environment_impact_assessments, :email_address, :string
  end
end
