# frozen_string_literal: true

class UpdateLocalAuthority < ActiveRecord::Migration[6.1]
  class LocalAuthority < ApplicationRecord; end

  def change
    LocalAuthority.find_each do |authority|
      if authority.subdomain == "southwark"
        authority.update(enquiries_paragraph: "Planning, London Borough of Southwark, PO Box 734, Winchester SO23 5DG")
      end
      if authority.subdomain == "lambeth"
        authority.update(enquiries_paragraph: "Planning, Buckinghamshire Council, Gatehouse Rd, Aylesbury HP19 8FF")
      end
      if authority.subdomain == "buckinghamshire"
        authority.update(enquiries_paragraph: "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG")
      end
    end
  end
end
