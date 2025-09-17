# frozen_string_literal: true

module BopsCore
  module LetterPreview
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :letter_template_id
      attribute :address_line_1, :string
      attribute :address_line_2, :string
      attribute :address_line_3, :string
      attribute :address_line_4, :string
      attribute :address_line_5, :string
      attribute :address_line_6, :string
      attribute :message, :string
      attribute :heading, :string
      attribute :personalisation_json, :string

      validates :letter_template_id, presence: true
      validates :address_line_1, :address_line_2, :address_line_3, presence: true
    end

    def personalisation
      base = {
        "address_line_1" => address_line_1,
        "address_line_2" => address_line_2,
        "address_line_3" => address_line_3,
        "address_line_4" => address_line_4,
        "address_line_5" => address_line_5,
        "address_line_6" => address_line_6,
        "heading" => heading,
        "message" => message
      }.compact

      base.merge(parsed_personalisation)
    end

    def parsed_personalisation
      return {} if personalisation_json.blank?

      JSON.parse(personalisation_json).tap { |h| h.transform_keys!(&:to_s) }
    rescue JSON::ParserError => e
      errors.add(:personalisation_json, "is invalid JSON: #{e.message}")
      {}
    end
  end
end
