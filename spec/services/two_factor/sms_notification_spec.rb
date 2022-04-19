# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactor::SmsNotification do
  let(:sms_notification) { described_class }

  describe "#deliver!" do
    let(:user) { create(:user) }

    context "when the request is successful" do
      it "calls send_sms on the notify client and makes a request" do
        notify_request = stub_post_sms_notification(phone_number: user.mobile_number, otp: user.current_otp, status: 200)

        sms_notification.new(user.mobile_number, user.current_otp).deliver!

        expect(notify_request).to have_been_requested
      end
    end
  end
end
