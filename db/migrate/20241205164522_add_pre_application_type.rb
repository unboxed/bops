# frozen_string_literal: true

class AddPreApplicationType < ActiveRecord::Migration[7.2]
  class ApplicationType < ActiveRecord::Base; end

  def change
    reversible do |dir|
      dir.up do
        next if ApplicationType.exists?(code: "preApp")

        ApplicationType.create(name: "other", code: "preApp", suffix: "PRE")
      end

      dir.down do
        next unless ApplicationType.exists?(code: "preApp")

        ApplicationType.find_by(code: "preApp").try(:tap) do |type|
          type.destroy!
        end
      end
    end
  end
end
