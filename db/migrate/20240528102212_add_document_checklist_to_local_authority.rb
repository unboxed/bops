# frozen_string_literal: true

class AddDocumentChecklistToLocalAuthority < ActiveRecord::Migration[7.1]
  class LocalAuthority < ActiveRecord::Base; end

  def change
    add_column :local_authorities, :document_checklist, :string

    up_only do
      LocalAuthority.reset_column_information

      LocalAuthority.where(subdomain: "lambeth")
        .update_all(document_checklist: "https://www.lambeth.gov.uk/sites/default/files/LAR_Final_22.07.2016.pdf")

      LocalAuthority.where(subdomain: "southwark")
        .update_all(document_checklist: "https://www.southwark.gov.uk/planning-and-building-control/planning-applications/how-to-prepare-a-valid-planning-application?chapter=7")

      LocalAuthority.where(subdomain: "buckinghamshire")
        .update_all(document_checklist: "https://www.buckinghamshire.gov.uk/planning-and-building-control/building-or-improving-your-property/how-to-prepare-a-valid-planning-application/")
    end
  end
end
