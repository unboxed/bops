# engines/bops_admin/app/models/bops_admin/letter_preview.rb
# frozen_string_literal: true

module BopsAdmin
  class LetterPreview
    include ActiveModel::Model
    include ActiveModel::Attributes

    # Form fields
    attribute :letter_template_id, :string
    attribute :sender_name,        :string
    attribute :sender_department,  :string
    attribute :recipient_name,     :string
    attribute :address_line1,      :string
    attribute :address_line2,      :string
    attribute :address_town,       :string
    attribute :address_postcode,   :string
    attribute :body,               :string
    attribute :personalisation_json, :string

    validates :letter_template_id, presence: true
    validates :recipient_name, presence: true
    validates :address_line1, :address_town, :address_postcode, presence: true

    def personalisation
      base = {
        "recipient_name"   => recipient_name,
        "sender_name"      => sender_name,
        "sender_department"=> sender_department,
        "address_line1"    => address_line1,
        "address_line2"    => address_line2,
        "address_town"     => address_town,
        "address_postcode" => address_postcode,
        "body"             => body
      }.compact

      base.merge(parsed_personalisation)
    end

    def parsed_personalisation
      return {} if personalisation_json.blank?
      JSON.parse(personalisation_json).tap do |h|
        h.transform_keys!(&:to_s)
      end
    rescue JSON::ParserError => e
      errors.add(:personalisation_json, "is invalid JSON: #{e.message}")
      {}
    end
  end
end
