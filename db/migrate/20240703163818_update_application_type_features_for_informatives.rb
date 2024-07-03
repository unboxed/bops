# frozen_string_literal: true

class UpdateApplicationTypeFeaturesForInformatives < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base
    def certificate_of_lawfulness?
      category == "certificate-of-lawfulness"
    end

    def planning_conditions?
      !!features["planning_conditions"]
    end

    def informatives
      certificate_of_lawfulness? || planning_conditions?
    end
  end

  def up
    ApplicationType.find_each do |type|
      type.update!(features: type.features.merge("informatives" => type.informatives))
    end
  end

  def down
    ApplicationType.find_each do |type|
      type.update!(features: type.features.except("informatives"))
    end
  end
end
