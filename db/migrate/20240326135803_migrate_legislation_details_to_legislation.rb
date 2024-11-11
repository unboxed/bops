# frozen_string_literal: true

class MigrateLegislationDetailsToLegislation < ActiveRecord::Migration[7.1]
  LEGISLATION_DETAILS = {
    "ldc.existing" => {
      title: "Town and Country Planning Act 1990, Section 191",
      link: "https://www.legislation.gov.uk/ukpga/1990/8/section/191"
    },
    "ldc.proposed" => {
      title: "Town and Country Planning Act 1990, Section 192",
      link: "https://www.legislation.gov.uk/ukpga/1990/8/section/192"
    },
    "pa.part1.classA" => {
      title: "The Town and Country Planning (General Permitted Development) (England) Order 2015 Part 1, Class A",
      link: "https://www.legislation.gov.uk/uksi/2015/596/schedule/2"
    },
    "pp.full.householder" => {
      title: "Town and Country Planning Act 1990",
      link: "https://www.legislation.gov.uk/ukpga/1990/8"
    },
    "default" => {
      title: "Town and Country Planning Act 1990",
      link: "https://www.legislation.gov.uk/ukpga/1990/8"
    }
  }.freeze

  def change
    up_only do
      ApplicationType.find_each do |type|
        next if type.legislation

        create_or_update_legislation_for!(type)
      end
    end
  end

  private

  def create_or_update_legislation_for!(type)
    details = LEGISLATION_DETAILS[type.code] || LEGISLATION_DETAILS["default"]

    legislation = Legislation.find_or_create_by!(title: details[:title])
    legislation.update!(link: details[:link])

    type.update!(legislation: legislation)
  end
end
