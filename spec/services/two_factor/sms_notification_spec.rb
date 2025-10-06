# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactor::SmsNotification do
  around do |example|
    freeze_time { example.run }
  end

  let(:notify_url) { "https://api.notifications.service.gov.uk/v2/notifications/sms" }
  let(:now) { Time.zone.now }
  let(:payload) { {iss: issuer, iat: now.to_i} }
  let(:bearer_token) { JWT.encode(payload, secret_token, "HS256") }

  describe "#deliver!" do
    let(:local_authority) { create(:local_authority, :default) }

    context "when the user is a local authority user" do
      let(:user) { create(:user, :administrator, local_authority:) }
      let(:issuer) { "c2a32a67-f437-46cd-9364-483d2cc4c43f" }
      let(:secret_token) { "523849d3-ca3b-4c12-b11a-09ed7d86de2e" }

      it "sends an SMS via the local authority’s GOV.UK Notify account" do
        headers = {
          "Authorization" => "Bearer #{bearer_token}"
        }

        body = {
          template_id: "296467e7-6723-465a-86b9-eb8c81a9199c",
          phone_number: user.mobile_number,
          personalisation: {
            body: "#{user.current_otp} is your Back Office Planning System verification code."
          }
        }.to_json

        notify_api =
          stub_request(:post, notify_url)
            .with(headers:, body:).to_return(status: 200, body: "{}")

        described_class.new(user, user.mobile_number).deliver!

        expect(notify_api).to have_been_requested
      end
    end

    context "when the user is a global administrator" do
      let(:user) { create(:user, :global_administrator, local_authority: nil) }
      let(:issuer) { "2fe56bca-73fb-4d4e-a8aa-375f36915de7" }
      let(:secret_token) { "34fd3a7f-6508-439c-b8c8-ccc189022749" }

      before do
        expect(Rails.configuration).to \
          receive(:default_notify_api_key).and_return("shared-#{issuer}-#{secret_token}")

        expect(Rails.configuration).to \
          receive(:default_sms_template_id).and_return("59132c41-52eb-456c-8986-05589fdcc233")
      end

      it "sends an SMS via the shared GOV.UK Notify account" do
        headers = {
          "Authorization" => "Bearer #{bearer_token}"
        }

        body = {
          template_id: "59132c41-52eb-456c-8986-05589fdcc233",
          phone_number: user.mobile_number,
          personalisation: {
            body: "#{user.current_otp} is your Back Office Planning System verification code."
          }
        }

        notify_api =
          stub_request(:post, notify_url)
            .with(headers:, body:).to_return(status: 200, body: "{}")

        described_class.new(user, user.mobile_number).deliver!

        expect(notify_api).to have_been_requested
      end
    end
  end
end
