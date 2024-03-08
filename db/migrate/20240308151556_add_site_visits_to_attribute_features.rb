# frozen_string_literal: true

class AddSiteVisitsToAttributeFeatures < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end

  def change
    up_only do
      ApplicationType.find_each do |type|
        next if type.name == "lawfulness_certificate"

        type.update!(features: type.features.merge("site_visits" => true))
      end
    end
  end
end
