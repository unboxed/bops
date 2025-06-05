# frozen_string_literal: true

class AddPrivacyPolicyToLocalAuthority < ActiveRecord::Migration[7.2]
  class LocalAuthority < ActiveRecord::Base; end

  PRIVACY_POLICIES = {
    "barnet" => "https://www.barnet.gov.uk/your-council/policies-plans-and-performance/privacy-notices",
    "buckinghamshire" => "https://www.buckinghamshire.gov.uk/your-council/privacy/privacy-and-planning-policy-and-compliance",
    "lambeth" => "https://beta.lambeth.gov.uk/about-council/privacy-data-protection/planning-transport-development-service-privacy-notice",
    "medway" => "https://www.medway.gov.uk/info/200217/freedom_of_information/347/data_protection/1",
    "southwark" => "https://www.southwark.gov.uk/terms-and-disclaimer/corporate-data-privacy-notice",
    "newcastle" => "https://www.newcastle.gov.uk/local-government/access-information-and-data/open-data/privacy-notice",
    "camden" => "https://www.camden.gov.uk/data-protection-privacy-and-cookies#yedw",
    "great-yarmouth" => "https://www.great-yarmouth.gov.uk/privacypolicy",
    "gloucester" => "https://www.gloucester.gov.uk/about-the-council/data-protection-and-freedom-of-information/data-protection/"
  }

  def change
    add_column :local_authorities, :privacy_policy_url, :string

    up_only do
      LocalAuthority.reset_column_information

      PRIVACY_POLICIES.each do |subdomain, privacy_policy_url|
        LocalAuthority.where(subdomain:).update!(privacy_policy_url:)
      end
    end
  end
end
