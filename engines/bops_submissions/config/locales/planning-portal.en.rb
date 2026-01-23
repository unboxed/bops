# frozen_string_literal: true

{
  en: {
    bops_submissions: {
      pp_to_odp_code: {
        1 => "pp.full.householder",
        2 => "pp.full.householder.demolition",
        3 => "pp.full.householder.listed",
        4 => ->(key, options) {
          site_area = options.dig(:params, "applicationData", "siteArea", "siteArea")
          area_unit = options.dig(:params, "applicationData", "siteArea", "areaUnit")
          floorspace = options.dig(:params, "applicationData", "nonResidentialDevelopment", "floorspace", "totalGrossFloorspaceProposed")
          dwellings = options.dig(:params, "applicationData", "residentialDevelopment", "proposedTotal")

          if area_unit == "sq.metres" && site_area >= 10000
            "pp.full.major"
          elsif area_unit == "hectares" && site_area >= 1
            "pp.full.major"
          elsif floorspace && floorspace >= 1000
            "pp.full.major"
          elsif dwellings && dwellings >= 10
            "pp.full.major"
          else
            "pp.full.minor"
          end
        },
        5 => "pp.outline.some",
        6 => "pp.outline.all",
        7 => "pp.full.demolition",
        8 => "pp.full.minor.listed",
        9 => "pp.full.advertConsent",
        10 => "pp.full.demolition",
        11 => "listed",
        12 => "advertConsent",
        14 => "ldc.existing",
        15 => "ldc.proposed",
        21 => "hedgerowRemovalNotice",
        23 => "approval.reservedMatters",
        25 => "amendment.minorMaterial",
        27 => "approval.conditions",
        31 => ->(key, options) {
          seeking_consent = options.dig(:params, "applicationData", "trees", "seekingConsentForTPO")

          if seeking_consent
            "wtt.consent"
          else
            "wtt.notice"
          end
        },
        34 => "amendment.nonMaterial",
        40 => "pa.part1.classA",
        61 => "pa.part1.classAA",
        64 => "pa.part3.classMA",
        65 => "pa.part3.classG",
        42 => "pa.part3.classM",
        44 => "pa.part3.classQ",
        45 => "pa.part3.classR",
        46 => "pa.part3.classS",
        47 => "pa.part3.classT",
        50 => "pa.part3.classN",
        56 => "pa.part20.classA",
        57 => "pa.part20.classAA",
        58 => "pa.part20.classAB",
        60 => "pa.part20.classAD",
        59 => "pa.part20.classAC",
        62 => "pa.part20.classZA",
        20 => "pa.part16.classA",
        16 => ->(key, options) {
          site_area = options.dig(:params, "applicationData", "siteArea", "siteArea")
          area_unit = options.dig(:params, "applicationData", "siteArea", "areaUnit")

          if area_unit == "sq.metres" && site_area >= 50000
            "pa.part6.classA"
          elsif area_unit == "hectares" && site_area >= 5
            "pa.part6.classA"
          else
            "pa.part6.classB"
          end
        },
        17 => "pa.part6.classE",
        18 => "pa.part6.classC",
        19 => ->(key, options) {
          site_area = options.dig(:params, "applicationData", "siteArea", "siteArea")
          area_unit = options.dig(:params, "applicationData", "siteArea", "areaUnit")

          if area_unit == "sq.metres" && site_area >= 50000
            "pa.part6.classA"
          elsif area_unit == "hectares" && site_area >= 5
            "pa.part6.classA"
          else
            "pa.part6.classB"
          end
        },
        51 => "pa.part7.classC",
        52 => "pa.part14.classJ",
        63 => "pa.part7.classM",
        66 => "pa.part4.classBB",
        67 => "pa.part19.classTA",
        73 => "pa.part14.classA",
        74 => "pa.part14.classB",
        75 => "pa.part14.classK",
        76 => "pa.part14.classOA",
        53 => "pa.part4.classCA",
        54 => "pa.part4.classE",
        22 => "pa.part11.classB"
      },

      pp_to_description: {
        1 => ->(key, options) {
          options.dig(:params, "applicationData", "proposalDescription", "descriptionText")
        },
        2 => ->(key, options) {
          options.dig(:params, "applicationData", "proposalDescription", "descriptionText")
        },
        3 => ->(key, options) {
          options.dig(:params, "applicationData", "proposalDescription", "descriptionText")
        },
        4 => ->(key, options) {
          options.dig(:params, "applicationData", "proposalDescription", "descriptionText")
        },
        5 => ->(key, options) {
          options.dig(:params, "applicationData", "proposalDescription", "descriptionText")
        },
        6 => ->(key, options) {
          options.dig(:params, "applicationData", "proposalDescription", "descriptionText")
        },
        7 => ->(key, options) {
          options.dig(:params, "applicationData", "proposalDescription", "descriptionText")
        },
        8 => ->(key, options) {
          options.dig(:params, "applicationData", "proposalDescription", "descriptionText")
        },
        9 => ->(key, options) {
          options.dig(:params, "applicationData", "proposalDescription", "descriptionText")
        }
      }
    }
  }
}
