# frozen_string_literal: true

class UpdateTreeworksToWorksToTrees < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end

  def change
    reversible do |dir|
      dir.up do
        ApplicationType.where(code: "treeWorksConsent").update_all(code: "wtt")
      end

      dir.down do
        ApplicationType.where(code: "wtt").update_all(code: "treeWorksConsent")
      end
    end
  end
end
