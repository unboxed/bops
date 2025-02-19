# frozen_string_literal: true

class AddCategoryToLocalAuthorityRequirement < ActiveRecord::Migration[7.2]
  class LocalAuthorityRequirement < ActiveRecord::Base; end

  def change
    safety_assured do
      add_column :local_authority_requirements, :category, :string, limit: 30

      up_only do
        LocalAuthorityRequirement.find_each do |requirement|
          requirement.update!(category: "other")
        end

        change_column_null :local_authority_requirements, :category, false
      end
    end
  end
end
