# frozen_string_literal: true

class LocalAuthorityDrop < ApplicationDrop
  with_options to: :@model do
    delegate :email_address
    delegate :signatory
  end

  def name
    @model.short_name
  end

  def full_name
    @model.council_name
  end

  def enquiries
    @model.enquiries_paragraph
  end
end
