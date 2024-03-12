# frozen_string_literal: true

class AddCodeAndSuffixToApplicationTypes < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end
  class PlanningApplication < ActiveRecord::Base; end

  def change
    change_table :application_types, bulk: true do |t|
      t.string :code
      t.string :suffix
    end

    reversible do |dir|
      dir.up do
        ApplicationType.reset_column_information

        ApplicationType.find_each do |type|
          case type.name
          when "lawfulness_certificate"
            type.code = "ldc.existing"
            type.suffix = "LDCE"
            type.save!

            new_type = type.dup
            new_type.code = "ldc.proposed"
            new_type.suffix = "LDCP"
            new_type.save!

            PlanningApplication
              .where(application_type_id: type.id)
              .where(work_status: "proposed")
              .update_all(application_type_id: new_type.id)

          when "prior_approval"
            type.code = "pa.part1.classA"
            type.suffix = "PA"
            type.save!

          when "planning_permission"
            type.code = "pp.full.householder"
            type.suffix = "HAPP"
            type.save!

          else
            raise "Unexpected application type: '#{type.name}'"
          end
        end

        change_column_null :application_types, :code, false
        change_column_null :application_types, :suffix, false

        add_index :application_types, :code, unique: true
        add_index :application_types, :suffix, unique: true
      end

      dir.down do
        ldc_proposed = ApplicationType.find_by!(code: "ldc.proposed")
        ldc_existing = ApplicationType.find_by!(code: "ldc.existing")

        PlanningApplication
          .where(application_type_id: ldc_proposed.id)
          .update_all(application_type_id: ldc_existing.id)

        ldc_proposed.destroy!
      end
    end
  end
end
