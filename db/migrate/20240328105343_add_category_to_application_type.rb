# frozen_string_literal: true

class AddCategoryToApplicationType < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end

  def change
    add_column :application_types, :category, :string

    up_only do
      ApplicationType.find_each do |type|
        type.category = \
          case type.code
          when /\Aldc\z/, /\Aldc\./
            "certificate-of-lawfulness"
          when /\Apa\z/, /\Apa\./
            "prior-approval"
          when /\App\.full\.householder\z/, /\App.full.householder\./
            "householder"
          when /\App\.full\z/, /\App.full\./
            "full"
          when /\App\.outline\z/, /\App.outline\./
            "outline"
          when /\App\z/, /\App\./
            "full"
          when "advertConsent"
            "advertisment"
          when "hedgerowRemovalNotice"
            "hedgerows"
          when "listed"
            "listed-building"
          when "nonMaterialAmendment"
            "non-material-amendment"
          when "treeWorksConsent"
            "tree-works"
          else
            "other"
          end

        type.save!
      end
    end
  end
end
