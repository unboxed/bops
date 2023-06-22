# frozen_string_literal: true

class CreateConstraints < ActiveRecord::Migration[7.0]
  # rubocop:disable Metrics/MethodLength
  def change
    create_table :constraints do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.references :local_authority, null: true, index: true, foreign_key: true

      t.timestamps
    end

    up_only do
      constraints_list = {
        flooding: [
          "Flood zone",
          "Flood zone 1",
          "Flood zone 2",
          "Flood zone 3"
        ],
        military_and_defence: [
          "Explosives & ordnance storage",
          "Safeguarded land"
        ],
        ecology: [
          "Special Area of Conservation (SAC)",
          "Site of Special Scientific Interest (SSSI)",
          "Ancient Semi-Natural Woodland (ASNW)",
          "Local Wildlife / Biological notification site",
          "Priority habitat"
        ],
        heritage_and_conservation: [
          "Listed Building",
          "Conservation Area",
          "Area of Outstanding Natural Beauty",
          "National Park",
          "World Heritage Site",
          "Broads"
        ],
        general_policy: [
          "Article 4 area",
          "Green belt"
        ],
        tree: [
          "Tree Preservation Order"
        ],
        other: [
          "Safety hazard area",
          "Within 3km of the perimeter of an aerodrome"
        ]
      }

      constraints_list.each do |category, names|
        names.each do |name|
          Constraint.create!(name:, category: category.to_s)
        rescue ActiveRecord::RecordInvalid, ArgumentError => e
          raise "Could not create constraint with category: '#{category}' and name: '#{name}' with error: #{e.message}"
        end
      end

      # Migrate local constraints from existing planning applications
      constraint_names = PlanningApplication.pluck(:old_constraints).flatten.uniq

      constraint_names.each do |name|
        next if Constraint.find_by(name:)

        Constraint.create!(name:, category: "local")
      rescue ActiveRecord::RecordInvalid, ArgumentError => e
        raise "Could not create constraint with category: '#{category}' and name: '#{name}' with error: #{e.message}"
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
