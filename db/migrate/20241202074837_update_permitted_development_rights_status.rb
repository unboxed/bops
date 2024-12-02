# frozen_string_literal: true

class UpdatePermittedDevelopmentRightsStatus < ActiveRecord::Migration[7.2]
  class PermittedDevelopmentRight < ActiveRecord::Base; end

  def change
    reversible do |dir|
      dir.up do
        PermittedDevelopmentRight
          .where(status: "checked")
          .update_all(status: "complete")

        PermittedDevelopmentRight
          .where(status: "removed")
          .update_all(status: "complete")
      end

      dir.down do
        PermittedDevelopmentRight
          .where(status: "complete", removed: true)
          .update_all(status: "removed")

        PermittedDevelopmentRight
          .where(status: "complete", removed: false)
          .update_all(status: "checked")
      end
    end
  end
end
