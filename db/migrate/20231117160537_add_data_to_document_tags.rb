# frozen_string_literal: true

class AddDataToDocumentTags < ActiveRecord::Migration[7.0]
  def up
    ApplicationType.find_each do |type|
      tags = {
        evidence: [
          "Photograph",
          "Utility Bill",
          "Building Control Certificate",
          "Construction Invoice",
          "Council Tax Document",
          "Tenancy Agreement",
          "Tenancy Invoice",
          "Bank Statement",
          "Statutory Declaration",
          "Other"
        ],
        plans: %w[
          Front
          Rear
          Side
          Roof
          Floor
          Site
          Plan
          Elevation
          Section
          Proposed
          Existing
        ],
        other: [
          "Site Visit",
          "Site Notice",
          "Press Notice"
        ]
      }

      type.update(document_tags: tags)
    end
  end

  def down
    ApplicationType.find_each do |type|
      type.update(document_tags: [])
    end
  end
end
