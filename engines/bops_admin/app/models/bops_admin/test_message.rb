# frozen_string_literal: true

# engines/bops_admin/app/models/bops_admin/test_message.rb
module BopsAdmin
  class TestMessage
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :channel, :string
    attribute :template_id, :string
    attribute :email, :string
    attribute :phone, :string
    attribute :subject, :string
    attribute :body, :string

    validates :channel, inclusion: {in: %w[email sms]}
    validates :template_id, presence: true

    with_options if: -> { channel == "email" } do
      validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
      validates :subject, presence: true
      validates :body, presence: true
    end

    with_options if: -> { channel == "sms" } do
      validates :phone, presence: true, format: {with: /\A\+?[0-9()\-\s]{7,}\z/}
    end

    def self.model_name = ActiveModel::Name.new(self, nil, "TestMessage")

    def personalisation
      if channel == "email"
        {"subject" => subject, "body" => body}.compact
      else
        {"body" => body}.compact
      end
    end
  end
end
