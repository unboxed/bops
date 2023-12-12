# frozen_string_literal: true

class UpdateDocumentTags < ActiveRecord::Migration[7.0]
  def up
    ApplicationType.find_each do |type|
      tags = if type.name == "lawfulness_certificate"
        {
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
          supporting_documents: []
        }
      else
        {
          evidence: [
            "Discounts"
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
          supporting_documents: [
            "Site Visit",
            "Site Notice",
            "Press Notice",
            "Design and Access Statement",
            "Planning Statement",
            "Viability Appraisal",
            "Heritage Statement",
            "Agricultural, Forestry or Occupational Worker Dwelling Justification",
            "Arboricultural Assessment",
            "Structural Survey/report",
            "Air Quality Assessment",
            "Basement Impact Assessment",
            "Biodiversity Net Gain (from April)",
            "Contaminated Land Assessment",
            "Daylight and Sunlight Assessment",
            "Flood Risk Assessment/Drainage and SuDs Report",
            "Landscape and Visual Impact Assessment",
            "Noise Impact Assessment",
            "Open Space Assessment",
            "Sustainability and Energy Statement",
            "Transport Statement",
            "NDSS Compliance Statement",
            "Ventilation/Extraction Statement",
            "Community Infrastructure Levy (CIL) form",
            "Gypsy and Traveller Statement",
            "HMO statement",
            "Specialist Accommodation Statement",
            "Student Accommodation Statement",
            "Other Supporting Document"
          ]
        }
      end

      type.update(document_tags: tags)
    end
  end

  def down
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
end
