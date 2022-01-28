# frozen_string_literal: true

class AddFeedbackEmailToLocalAuthorities < ActiveRecord::Migration[6.1]
  def up
    add_column :local_authorities, :feedback_email, :string

    LocalAuthority.find_each do |authority|
      authority.subdomain == "lambeth" && authority.update(feedback_email: "digitalplanning@lambeth.gov.uk")
      authority.subdomain == "southwark" && authority.update(feedback_email: "digital.projects@southwark.gov.uk")
      if authority.subdomain == "buckinghamshire"
        authority.update(feedback_email: "planning.digital@buckinghamshire.gov.uk")
      end
    end
  end

  def down
    remove_column :local_authorities, :feedback_email, :string
  end
end
