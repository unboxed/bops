# frozen_string_literal: true

class AddReferenceToEnforcement < ActiveRecord::Migration[8.1]
  class CaseRecord < ActiveRecord::Base
    belongs_to :local_authority
    belongs_to :caseable, class_name: :Enforcement
  end

  class LocalAuthority < ActiveRecord::Base
    class ApplicationNumber < ActiveRecord::Base
      belongs_to :local_authority

      class << self
        def current_year(year = Time.zone.today.year)
          find_or_create_by!(year:) do |counter|
            counter.application_number = 99
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      def next_application_number
        with_lock do
          increment!(:application_number)
        end

        application_number
      end
    end

    has_many :application_numbers
    has_many :case_records
    has_many :enforcements, through: :case_records
  end

  def change
    add_column :enforcements, :reference, :string

    up_only do
      [2025, 2026].each do |year|
        # Looping over CaseRecord rather than Enforcement because the relationships are hard to get right without
        # duplicating the entire models.
        CaseRecord.where(caseable_type: "Enforcement", created_at: Time.zone.local(year).all_year).find_each do |case_record|
          current_year = case_record.local_authority.application_numbers.current_year(year)

          # not just using the model's set_reference because we may need to account for older cases, at least in
          # staging; but in real use that method will never need to account for anything but the current year.
          case_record.caseable.update!(reference: [
            format("%02d", year),
            format("%05d", current_year.next_application_number),
            "ENF"
          ].join("-"))
        end
      end
    end
  end
end
