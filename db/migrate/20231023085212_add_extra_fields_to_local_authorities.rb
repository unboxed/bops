# frozen_string_literal: true

class AddExtraFieldsToLocalAuthorities < ActiveRecord::Migration[7.0]
  class LocalAuthority < ActiveRecord::Base
    def plan_x?
      council_code == "PlanX"
    end
  end

  def change
    add_column :local_authorities, :short_name, :string
    add_column :local_authorities, :council_name, :string
    add_column :local_authorities, :applicants_url, :string

    up_only do
      LocalAuthority.find_each do |la|
        name = la.plan_x? ? la.council_code : la.subdomain.titleize

        la.short_name = name
        la.council_name = "#{name} Council"
        la.applicants_url = \
          case ENV.fetch("APPLICANTS_APP_HOST", nil)
          when "planningapplications"
            "https://#{la.subdomain}.planningapplications.gov.uk"
          when "bops-applicants-staging.services"
            "https://#{la.subdomain}.bops-applicants-staging.services"
          else
            "https://#{la.subdomain}.bops-applicants.localhost:3001"
          end

        la.save!
      end

      change_column_null :local_authorities, :short_name, false
      change_column_null :local_authorities, :council_name, false
      change_column_null :local_authorities, :applicants_url, false
    end
  end
end
