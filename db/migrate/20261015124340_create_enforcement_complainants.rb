# frozen_string_literal: true

class CreateEnforcementComplainants < ActiveRecord::Migration[8.1]
  class CaseRecord < ActiveRecord::Base
    belongs_to :submission, optional: true
    belongs_to :caseable, inverse_of: :case_record
  end

  class Submission < ActiveRecord::Base
    has_one :case_record
  end

  class Enforcement < ActiveRecord::Base
    class Complainant < ActiveRecord::Base
      belongs_to :enforcement
    end
    has_many :complainants

    has_one :case_record, foreign_key: :caseable_id
    delegate :submission, to: :case_record
  end

  def change
    create_table :enforcement_complainants do |t|
      t.references :enforcement
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :address_1
      t.string :address_2
      t.string :town
      t.string :county
      t.string :country
      t.string :postcode

      t.timestamps
    end

    up_only do
      Enforcement.find_each do |enforcement|
        next if enforcement.complainants.any?
        next unless enforcement.case_record.submission

        complainant_data = enforcement.case_record.submission&.request_body&.dig("data", "complainant")
        enforcement.complainants.create!(
          first_name: complainant_data.dig("name", "first"),
          last_name: complainant_data.dig("name", "last"),
          email: complainant_data.dig("email"),
          phone: complainant_data.dig("phone", "primary"),
          address_1: complainant_data.dig("address", "line1"),
          town: complainant_data.dig("address", "town"),
          postcode: complainant_data.dig("address", "postcode"),
          country: complainant_data.dig("address", "country")
        )
      end
    end
  end
end
