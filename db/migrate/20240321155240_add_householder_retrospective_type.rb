# frozen_string_literal: true

class AddHouseholderRetrospectiveType < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end

  def change
    reversible do |dir|
      dir.up do
        next if ApplicationType.exists?(code: "pp.full.householder.retro")

        ApplicationType.find_by(code: "pp.full.householder").try(:tap) do |type|
          type.dup.tap do |new_type|
            new_type.code = "pp.full.householder.retro"
            new_type.suffix = "HRET"
            new_type.save!
          end
        end
      end

      dir.down do
        next unless ApplicationType.exists?(code: "pp.full.householder.retro")

        ApplicationType.find_by(code: "pp.full.householder.retro").try(:tap) do |type|
          type.destroy!
        end
      end
    end
  end
end
