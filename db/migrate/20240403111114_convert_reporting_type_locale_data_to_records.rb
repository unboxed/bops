# frozen_string_literal: true

class ConvertReportingTypeLocaleDataToRecords < ActiveRecord::Migration[7.1]
  class ReportingType < ActiveRecord::Base; end

  REPORTING_TYPES = [
    ["Q01", "full", "Dwellings (major)", nil],
    ["Q02", "full", "Offices, R&D, and light industry (major)", nil],
    ["Q03", "full", "General Industry, storage and warehousing (major)", nil],
    ["Q04", "full", "Retail and services (major)", nil],
    ["Q05", "full", "Traveller caravan pitches (major)", nil],
    ["Q06", "full", "All other developments (major)", nil],
    ["Q07", "full", "Major Public Service infrastructure developments", nil],
    ["Q13", "full", "Dwellings (minor)", nil],
    ["Q14", "full", "Offices, R&D, and light industry (minor)", nil],
    ["Q15", "full", "General Industry, storage and warehousing (minor)", nil],
    ["Q16", "full", "Retail and services (minor)", nil],
    ["Q17", "full", "Traveller caravan pitches (minor)", nil],
    ["Q18", "full", "All other developments (minor)", nil],
    ["Q20", "change-of-use", "Change of use", nil],
    ["Q21", "householder", "Householder developments", nil],
    ["Q22", "advertisment", "Advertisements", nil],
    ["Q23", "listed-building", "Listed building consents to alter/extend", nil],
    ["Q24", "listed-building", "Listed building consents to demolish", nil],
    ["Q25", "conservation-area", "Relevant demolition in a conservation area", nil],
    ["Q26", "certificate-of-lawfulness", "Certificates of lawful development", nil],
    ["PA1", "prior-approval", "Larger householder extensions", "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 1, Class A"],
    ["PA2", "prior-approval", "Offices to residential", "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 1, Class A"],
    ["PA7", "prior-approval", "Launderette, betting office, pay day loan shop, hot food takeaway, amusement arcade or centre, or casino to residential", "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 3, Classes M and N"],
    ["PA8", "prior-approval", "Agricultural to residential", "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 1, Class A"],
    ["PA15", "prior-approval", "Building upwards to create dwellinghouses on detached commercial or mixed-use buildings", "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 20, Class AA"],
    ["PA16", "prior-approval", "Building upwards to create dwellinghouses on detached dwellinghouses", "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 20, Class AD"],
    ["PA17", "prior-approval", "Building upwards to create dwellinghouses on detached blocks of flats", "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 20, Class A"],
    ["PA18", "prior-approval", "Building upwards householder extensions", "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 1, Class AA"],
    ["PA19", "prior-approval", "Demolition of buildings and construction of dwellinghouses", "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 20, Class ZA"],
    ["PA20", "prior-approval", "Building upwards to create dwellinghouses on commercial or mixed-use buildings in a terrace", "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 20, Class AB"]
  ]

  def change
    reversible do |dir|
      dir.up do
        REPORTING_TYPES.each do |code, category, description, legislation|
          ReportingType.create!(code:, category:, description:, legislation:)
        end
      end

      dir.down do
        ReportingType.delete_all
      end
    end
  end
end
