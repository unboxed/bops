# frozen_string_literal: true

class UpdateEnquiriesParagraph < ActiveRecord::Migration[6.1]
  def change
    up_only do
      LocalAuthority.find_each do |authority|
        if authority.subdomain == "southwark"
          authority.update(enquiries_paragraph:
            "Planning, London Borough of Southwark, PO Box 734, Winchester SO23 5DG")
        end
        if authority.subdomain == "lambeth"
          authority.update(enquiries_paragraph:
             "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG")
        end
        if authority.subdomain == "buckinghamshire"
          authority.update(enquiries_paragraph:
             "Planning, Buckinghamshire Council, Gatehouse Rd, Aylesbury HP19 8FF")
        end
      end
    end
  end
end
