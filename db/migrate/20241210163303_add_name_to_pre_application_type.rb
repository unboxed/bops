# frozen_string_literal: true

class AddNameToPreApplicationType < ActiveRecord::Migration[7.2]
  class ApplicationType < ActiveRecord::Base; end

  def up
    application_type = ApplicationType.find_by(code: "preApp")

    if application_type.present?
      application_type.update!(name: "pre_application")
    else
      Rails.logger.debug { "ApplicationType with code 'preApp' not found" }
    end
  end

  def down
    application_type = ApplicationType.find_by(code: "preApp")

    if application_type.present?
      application_type.update!(name: "other")
    else
      Rails.logger.debug { "ApplicationType with code 'preApp' not found" }
    end
  end
end
